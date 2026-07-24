#!/usr/bin/env bash
set -Eeuo pipefail

readonly USERNAME="opencode"
readonly GROUPNAME="opencode"

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

validate_id() {
    local name="$1"
    local value="$2"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "${name} must be numeric; received '${value}'." >&2
        exit 1
    fi

    if [[ "$value" -eq 0 ]]; then
        echo "${name} must not be 0; refusing to run OpenCode as root." >&2
        exit 1
    fi
}

validate_id "PUID" "$PUID"
validate_id "PGID" "$PGID"

current_uid="$(id -u "$USERNAME")"
current_gid="$(id -g "$USERNAME")"

if [[ "$current_gid" != "$PGID" ]]; then
    existing_group="$(getent group "$PGID" | cut -d: -f1 || true)"
    if [[ -n "$existing_group" && "$existing_group" != "$GROUPNAME" ]]; then
        echo "PGID ${PGID} is already assigned to group '${existing_group}'." >&2
        exit 1
    fi
    groupmod -g "$PGID" "$GROUPNAME"
fi

if [[ "$current_uid" != "$PUID" ]]; then
    existing_user="$(getent passwd "$PUID" | cut -d: -f1 || true)"
    if [[ -n "$existing_user" && "$existing_user" != "$USERNAME" ]]; then
        echo "PUID ${PUID} is already assigned to user '${existing_user}'." >&2
        exit 1
    fi
    usermod -u "$PUID" "$USERNAME"
fi

mkdir -p \
    /workspace \
    /home/opencode/.config/opencode \
    /home/opencode/.local/share/opencode \
    /home/opencode/.cache \
    /home/opencode/.cargo \
    /home/opencode/.config/gh

# Fix the small home/state tree, but do not recursively scan a potentially
# large bind-mounted workspace.
chown -R "$PUID:$PGID" /home/opencode
chown "$PUID:$PGID" /workspace 2>/dev/null || true

export HOME=/home/opencode
export USER="$USERNAME"
export LOGNAME="$USERNAME"
export CARGO_HOME=/home/opencode/.cargo

exec su-exec "${PUID}:${PGID}" "$@"
