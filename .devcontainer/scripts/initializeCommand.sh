#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  if grep -qE '^[A-Za-z_][A-Za-z0-9_]*=.*$' "$ENV_FILE"; then
    source <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=.*$' "$ENV_FILE")
  else
    echo "Warning: .env exists but has no valid KEY=VALUE entries. Continuing with defaults." >&2
  fi
  set +a
else
  echo "Warning: .env file not found at $ENV_FILE. Continuing with defaults." >&2
fi

if [ -z "${SSH_AGENT_SOCK:-}" ]; then
  SSH_AGENT_SOCK="/tmp/ssh-agent.sock"
  echo "Warning: SSH_AGENT_SOCK is not set. Using default: $SSH_AGENT_SOCK" >&2
fi

mkdir -p "$(dirname "$SSH_AGENT_SOCK")"

agent_running=false
if [ -S "$SSH_AGENT_SOCK" ]; then
  set +e
  SSH_AUTH_SOCK="$SSH_AGENT_SOCK" ssh-add -l >/dev/null 2>&1
  rc=$?
  set -e

  case "$rc" in
    0|1) agent_running=true ;;
    *) rm -f "$SSH_AGENT_SOCK" ;;
  esac
fi

if [ "$agent_running" = false ]; then
  eval "$(ssh-agent -a "$SSH_AGENT_SOCK")" >/dev/null
  echo "ssh-agent started at: $SSH_AGENT_SOCK"
else
  echo "SSH agent is already running at: $SSH_AGENT_SOCK"
fi

if [ -n "${SSH_ADD_KEYS:-}" ]; then
  IFS=':' read -r -a key_paths <<< "$SSH_ADD_KEYS"
  for key_path in "${key_paths[@]}"; do
    [ -z "$key_path" ] && continue
    case "$key_path" in
      "~") key_path="$HOME" ;;
      ~/*) key_path="$HOME/${key_path#~/}" ;;
    esac

    if [ ! -f "$key_path" ]; then
      echo "Warning: key file not found, skipping: $key_path" >&2
      continue
    fi

    SSH_AUTH_SOCK="$SSH_AGENT_SOCK" ssh-add "$key_path" || \
      echo "Warning: failed to add key: $key_path" >&2
  done
fi
