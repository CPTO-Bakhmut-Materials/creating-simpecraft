#!/usr/bin/env bash
# Builds the non-interactive in-browser demos (love.js):
#   * lesson demos in book/<lesson>/demo/: the unchanged lesson code + tools/demo/main.lua
#     (camera script from tools/demo/paths/<lesson>.lua) and tools/demo/conf.lua (runtime version);
#   * samples <lesson>/samples/<name>/ (standalone non-interactive LÖVE programs) in
#     book/<lesson>/samples/<name>/, with tools/demo/conf.lua only.
# The love.js / love.wasm runtime is shared: book/demo-runtime/.
#
# Usage: LOVEJS=/path/to/love.js tools/build-demos.sh
#   LOVEJS is a clone of https://github.com/cptobakhmut925-glitch/love.js with `npm ci` done.
#   Run after mdbook build (tools/build-book.sh does this itself).
#   Without LOVEJS only the demo pages are written: they show the lesson's static image.
set -euo pipefail
cd "$(dirname "$0")/.."

# Demo page: $1 is the folder in book/, $2 the title, $3 the relative path to book/demo-runtime.
write_page() {
    mkdir -p "$1"
    sed -e "s#__TITLE__#$2#" -e "s#__RUNTIME__#$3#" tools/demo/index.html > "$1/index.html"
}

if [ -z "${LOVEJS:-}" ]; then
    for path in tools/demo/paths/*.lua; do
        lesson=$(basename "$path" .lua)
        write_page "book/$lesson/demo" "$lesson" "../../demo-runtime"
    done
    for sample in [0-9][0-9]-*/samples/*/; do
        sample=${sample%/}
        write_page "book/$sample" "$(basename "$sample")" "../../../demo-runtime"
    done
    echo "demos: LOVEJS not set — wrote fallback pages only (lessons show their static images)"
    exit 0
fi

runtime=book/demo-runtime
mkdir -p "$runtime"
# compat is the single-threaded build: it needs no COOP/COEP headers, which GitHub Pages can't send.
cp "$LOVEJS/src/compat/love.js" "$LOVEJS/src/compat/love.wasm" "$runtime/"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

for path in tools/demo/paths/*.lua; do
    lesson=$(basename "$path" .lua)
    game="$work/$lesson/game"
    packed="$work/$lesson/packed"
    mkdir -p "$game"
    cp -r "$lesson/code/." "$game/"
    rm -rf "$game/tests"
    mv "$game/main.lua" "$game/lesson_main.lua"
    mv "$game/conf.lua" "$game/lesson_conf.lua"
    cp tools/demo/main.lua tools/demo/conf.lua "$game/"
    cp "$path" "$game/demo_path.lua"

    node "$LOVEJS/index.js" --compatibility --title "$lesson" "$game" "$packed" >/dev/null

    out="book/$lesson/demo"
    write_page "$out" "$lesson" "../../demo-runtime"
    cp "$packed/game.js" "$packed/game.data" "$out/"
    echo "demo: $out ($(du -h "$out/game.data" | cut -f1))"
done

for sample in [0-9][0-9]-*/samples/*/; do
    sample=${sample%/}
    name=$(basename "$sample")
    game="$work/samples/$sample/game"
    packed="$work/samples/$sample/packed"
    mkdir -p "$game"
    cp -r "$sample/." "$game/"
    mv "$game/conf.lua" "$game/lesson_conf.lua"
    cp tools/demo/conf.lua "$game/"

    node "$LOVEJS/index.js" --compatibility --title "$name" "$game" "$packed" >/dev/null

    out="book/$sample"
    write_page "$out" "$name" "../../../demo-runtime"
    cp "$packed/game.js" "$packed/game.data" "$out/"
    echo "demo: $out ($(du -h "$out/game.data" | cut -f1))"
done
