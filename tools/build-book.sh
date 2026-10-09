#!/usr/bin/env bash
# Builds the book into ./book and packs each lesson's code into <lesson>/code.zip.
# Usage: tools/build-book.sh   (needs mdbook on PATH, or MDBOOK=/path/to/mdbook, and zip)
set -euo pipefail
cd "$(dirname "$0")/.."
"${MDBOOK:-mdbook}" build
for dir in [0-9][0-9]-*/code; do
    lesson="${dir%/code}"
    (cd "$lesson" && zip -qr "../book/$lesson/code.zip" code)
done
touch book/.nojekyll
echo "Book written to $(pwd)/book"
