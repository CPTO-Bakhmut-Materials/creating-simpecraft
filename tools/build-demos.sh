#!/usr/bin/env bash
# Збирає неінтерактивні демо для браузера (love.js):
#   * демо уроків у book/<урок>/demo/ — код уроку без змін + tools/demo/main.lua
#     (сценарій камери з tools/demo/paths/<урок>.lua) і tools/demo/conf.lua (версія рушія);
#   * приклади <урок>/samples/<назва>/ (окремі неінтерактивні програми LÖVE) у
#     book/<урок>/samples/<назва>/ — лише з tools/demo/conf.lua.
# Рушій love.js / love.wasm спільний: book/demo-runtime/.
#
# Використання: LOVEJS=/шлях/до/love.js tools/build-demos.sh
#   LOVEJS — клон https://github.com/cptobakhmut925-glitch/love.js з виконаним `npm ci`.
#   Запускати після mdbook build (tools/build-book.sh робить це сам).
#   Без LOVEJS пишемо лише сторінки демо: вони показують статичну картинку уроку.
set -euo pipefail
cd "$(dirname "$0")/.."

# Сторінка демо: $1 — тека в book/, $2 — назва, $3 — відносний шлях до book/demo-runtime.
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
# compat — однопотокова збірка: не потребує заголовків COOP/COEP, яких GitHub Pages не надсилає.
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
