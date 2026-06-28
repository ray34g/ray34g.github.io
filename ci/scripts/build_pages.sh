#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-public}"
HUGO_ENV="${HUGO_ENVIRONMENT:-production}"

echo "[build] environment=${HUGO_ENV} output=${OUT_DIR}"

if ! command -v hugo >/dev/null 2>&1; then
  echo "[build] ERROR: hugo command not found" >&2
  exit 1
fi

hugo --gc --minify --cleanDestinationDir --environment "${HUGO_ENV}" --destination "${OUT_DIR}"

echo "[build] done"
