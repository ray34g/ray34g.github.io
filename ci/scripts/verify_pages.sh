#!/usr/bin/env bash
set -euo pipefail

PUBLIC_DIR="${1:-public}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

echo "[verify] target=${PUBLIC_DIR}"

if [[ ! -d "${PUBLIC_DIR}" ]]; then
  echo "[verify] ERROR: directory not found: ${PUBLIC_DIR}" >&2
  exit 1
fi

required=(
  "index.html"
  "ja/index.html"
  "en/index.html"
  "sitemap.xml"
  "robots.txt"
)

for f in "${required[@]}"; do
  if [[ ! -f "${PUBLIC_DIR}/${f}" ]]; then
    echo "[verify] ERROR: missing required output: ${PUBLIC_DIR}/${f}" >&2
    exit 1
  fi
done

echo "[verify] required pages check passed"

missing_refs=0
while IFS= read -r file; do
  while IFS= read -r ref; do
    path="${ref%%[?#]*}"
    [[ -z "${path}" ]] && continue
    [[ "${path}" == "/" ]] && continue
    [[ "${path}" == http://* || "${path}" == https://* || "${path}" == mailto:* || "${path}" == tel:* || "${path}" == data:* || "${path}" == javascript:* || "${path}" == \#* ]] && continue

    if [[ "${path}" == /* ]]; then
      target="${PUBLIC_DIR}${path}"
    else
      target="$(dirname "${file}")/${path}"
    fi

    if [[ ! -e "${target}" ]]; then
      echo "[verify] MISSING REF in ${file#"${PUBLIC_DIR}"/}: ${ref} -> ${target#"${PUBLIC_DIR}"/}"
      missing_refs=1
    fi
  done < <(rg -No '(?:href|src)="([^"]+)"' "${file}" --replace '$1' || true)
done < <(find "${PUBLIC_DIR}" -type f -name '*.html' | sort)

if [[ "${missing_refs}" -ne 0 ]]; then
  echo "[verify] ERROR: missing local references detected" >&2
  exit 1
fi

echo "[verify] local reference check passed"

"${ROOT_DIR}/ci/scripts/check_i18n_keys.sh"

echo "[verify] done"
