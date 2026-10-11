#!/usr/bin/env bash
# Builds the book (tools/build.sh) and serves it at http://localhost:<port>/.
# Usage: tools/serve.sh [port]           (default port 8000)
#        SKIP_BUILD=1 tools/serve.sh     serve the existing book/ without rebuilding
set -euo pipefail
cd "$(dirname "$0")/.."
port="${1:-8000}"

command -v python3 >/dev/null || { echo "error: 'python3' not found (used as the web server)" >&2; exit 1; }
if [ -z "${SKIP_BUILD:-}" ]; then
    tools/build.sh
fi
[ -f book/index.html ] || { echo "error: book/ is not built — run without SKIP_BUILD" >&2; exit 1; }

echo "Serving the book at http://localhost:$port/  (Ctrl+C to stop)"
exec python3 -m http.server --directory book --bind 127.0.0.1 "$port"
