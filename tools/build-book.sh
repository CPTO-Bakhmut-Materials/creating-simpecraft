#!/usr/bin/env bash
# Builds the book into ./book, packs each lesson's code into <lesson>/code.zip
# and builds the in-browser lesson demos (tools/build-demos.sh).
# Usage: tools/build-book.sh   (needs mdbook on PATH, or MDBOOK=/path/to/mdbook, and zip;
#        for live demos also LOVEJS=/path/to/love.js and node — without them the demo
#        frames fall back to the lessons' static images)
set -euo pipefail
cd "$(dirname "$0")/.."
"${MDBOOK:-mdbook}" build
for dir in [0-9][0-9]-*/code; do
    lesson="${dir%/code}"
    (cd "$lesson" && zip -qr "../book/$lesson/code.zip" code)
done
tools/build-demos.sh
touch book/.nojekyll
echo "Book written to $(pwd)/book"
