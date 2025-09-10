#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_PORT=3000

pick_port() {
  local p=$DEFAULT_PORT
  while lsof -i tcp:$p >/dev/null 2>&1; do
    p=$((p+1))
    if [ $p -gt 49151 ]; then
      echo "Error: No free port found from $DEFAULT_PORT..49151" >&2
      exit 1
    fi
  done
  echo "$p"
}

PORT="$(pick_port)"
API_URL="http://localhost:${PORT}"

echo "[1/4] Checking prerequisites..."
if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is required. Install Node 18+ and retry." >&2
  exit 1
fi
NODE_MAJOR="$(node -v | sed 's/v//' | cut -d. -f1)"
if [ "${NODE_MAJOR}" -lt 18 ]; then
  echo "Warning: Node ${NODE_MAJOR} detected. Node 18+ recommended for fetch() support." >&2
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: Flutter is required. Install Flutter 3.19+ and retry." >&2
  exit 1
fi

echo "[2/4] Building Flutter web app..."
pushd "$ROOT_DIR/front_end/app" >/dev/null
flutter config --enable-web >/dev/null || true
flutter pub get
flutter build web --dart-define=API_BASE_URL="$API_URL"
popd >/dev/null

echo "[3/4] Installing backend deps (if needed)..."
pushd "$ROOT_DIR/backend" >/dev/null
# Install if node_modules missing or if a required package (dotenv) is absent
if [ ! -d node_modules ] || [ ! -d node_modules/dotenv ]; then
  npm install
fi

echo "[4/4] Starting backend on ${API_URL} ..."
export PORT
exec npm start
