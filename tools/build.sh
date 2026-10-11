#!/usr/bin/env bash
# Full build of the book with live lesson demos, same as CI.
# Fetches the pinned tools (tools/versions.env) into .tools/ on first run or when a
# version changes: mdBook, mdbook-katex and the love.js fork (with its npm deps).
# Usage: tools/build.sh
# Needs: Linux x86_64, curl, tar, git, zip, node + npm.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/versions.env

need() {
    command -v "$1" >/dev/null || { echo "error: '$1' not found${2:+ — $2}" >&2; exit 1; }
}
need curl
need tar
need git
need zip
need node "install Node.js 18 or newer"
need npm
if [ "$(uname -sm)" != "Linux x86_64" ]; then
    echo "error: tools/build.sh downloads Linux x86_64 binaries; on $(uname -sm) install mdbook and" \
         "mdbook-katex yourself and run LOVEJS=… tools/build-book.sh" >&2
    exit 1
fi

TOOLS="$PWD/.tools"
BIN="$TOOLS/bin"
LOVEJS="$TOOLS/love.js"
mkdir -p "$BIN"

if ! "$BIN/mdbook" --version 2>/dev/null | grep -qx "mdbook v$MDBOOK_VERSION"; then
    echo "fetching mdBook $MDBOOK_VERSION"
    curl -fsSL "https://github.com/rust-lang/mdBook/releases/download/v$MDBOOK_VERSION/mdbook-v$MDBOOK_VERSION-x86_64-unknown-linux-gnu.tar.gz" \
        | tar -xz -C "$BIN"
fi

if ! "$BIN/mdbook-katex" --version 2>/dev/null | grep -qx "mdbook-katex $MDBOOK_KATEX_VERSION"; then
    echo "fetching mdbook-katex $MDBOOK_KATEX_VERSION"
    curl -fsSL "https://github.com/lzanini/mdbook-katex/releases/download/$MDBOOK_KATEX_VERSION-binaries/mdbook-katex-v$MDBOOK_KATEX_VERSION-x86_64-unknown-linux-gnu.tar.gz" \
        | tar -xz -C "$BIN"
fi

if [ "$(git -C "$LOVEJS" rev-parse HEAD 2>/dev/null)" != "$LOVEJS_COMMIT" ]; then
    echo "fetching love.js @ ${LOVEJS_COMMIT:0:7}"
    rm -rf "$LOVEJS"
    git init -q "$LOVEJS"
    git -C "$LOVEJS" fetch -q --depth 1 "$LOVEJS_REPO" "$LOVEJS_COMMIT"
    git -C "$LOVEJS" checkout -q FETCH_HEAD
fi
if [ ! -d "$LOVEJS/node_modules" ]; then
    echo "installing love.js dependencies"
    npm ci --omit=dev --no-audit --no-fund --prefix "$LOVEJS" >/dev/null
fi

# mdbook finds the mdbook-katex preprocessor on PATH.
PATH="$BIN:$PATH" MDBOOK="$BIN/mdbook" LOVEJS="$LOVEJS" tools/build-book.sh
