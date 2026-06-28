#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

mkdir -p "$HOME/.local/.profile.d" "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

BASHRC="$HOME/.bashrc"
MARKER_BEGIN="# >>> local profile.d >>>"
if ! grep -qF "$MARKER_BEGIN" "$BASHRC" 2>/dev/null; then
  cat >>"$BASHRC" <<'EOF'

# >>> local profile.d >>>
if [ -d "$HOME/.local/.profile.d" ]; then
  for f in "$HOME/.local/.profile.d"/*.sh; do
    [ -r "$f" ] && . "$f"
  done
fi
# <<< local profile.d <<<
EOF
fi

cat > "$HOME/.local/.profile.d/10-defaults.sh" <<'EOF'
export HISTSIZE=20000
export HISTFILESIZE=20000
shopt -s histappend
export EDITOR=vim
EOF

cat > "$HOME/.tmux.conf" <<'EOF'
set -g mouse on
set -g history-limit 200000
setw -g mode-keys vi
EOF

WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
if [ -d "$WORKSPACE_DIR/.git" ] || git -C "$WORKSPACE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git config --global --add safe.directory "$WORKSPACE_DIR" || true
fi

CONTAINER_SSH_AUTH_SOCK="/ssh-agent"
GIT_SSH_HOSTS=""
SSH_STRICT_HOSTKEY="accept-new"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  if grep -qE '^[A-Za-z_][A-Za-z0-9_]*=.*$' "$ENV_FILE"; then
    source <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=.*$' "$ENV_FILE")
  fi
  set +a
fi

cat > "$HOME/.local/.profile.d/20-ssh-agent.sh" <<EOF
export SSH_AUTH_SOCK=${CONTAINER_SSH_AUTH_SOCK}
EOF

mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh/config.d"
touch "$HOME/.ssh/known_hosts"
chmod 600 "$HOME/.ssh/known_hosts"

CFG="$HOME/.ssh/config"
touch "$CFG"
chmod 600 "$CFG"
INCLUDE_LINE='Include ~/.ssh/config.d/*.conf'
grep -qF "$INCLUDE_LINE" "$CFG" || printf "\n%s\n" "$INCLUDE_LINE" >> "$CFG"

OUT="$HOME/.ssh/config.d/git-ssh-hosts.conf"
: > "$OUT"
chmod 600 "$OUT"

if [ -n "${GIT_SSH_HOSTS:-}" ]; then
  IFS=';' read -r -a HOSTS <<< "$GIT_SSH_HOSTS"
  for entry in "${HOSTS[@]}"; do
    [ -z "$entry" ] && continue
    IFS=',' read -r NAME ADDR USER <<< "$entry"

    if [ -z "${NAME:-}" ] || [ -z "${ADDR:-}" ] || [ -z "${USER:-}" ]; then
      echo "Warning: bad GIT_SSH_HOSTS entry: '$entry' (expected name,addr,user). Skipping." >&2
      continue
    fi

    cat >> "$OUT" <<EOF
Host ${NAME}
  HostName ${ADDR}
  User ${USER}
  IdentityAgent ${CONTAINER_SSH_AUTH_SOCK}
  RequestTTY no
  ControlMaster no
  ServerAliveInterval 30
  ServerAliveCountMax 4
  StrictHostKeyChecking ${SSH_STRICT_HOSTKEY}

EOF
  done
fi

echo "postCreateCommand completed."
