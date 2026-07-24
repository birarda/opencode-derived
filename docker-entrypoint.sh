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
existing_user="$(getent passwd "$PUID" | cut -d: -f1 || true)"
existing_group="$(getent group "$PGID" | cut -d: -f1 || true)"

# Preserve existing identities such as Unraid's nobody:users (99:100).
# If the requested UID is unused—or already belongs to our bundled account—
# remap the account for friendlier username output. Otherwise, leave passwd
# and group records untouched and launch with the numeric IDs below.
if [[ -z "$existing_user" || "$existing_user" == "$USERNAME" ]]; then
    if [[ -n "$existing_group" ]]; then
        usermod -g "$existing_group" "$USERNAME"
    else
        groupmod -g "$PGID" "$GROUPNAME"
        usermod -g "$GROUPNAME" "$USERNAME"
    fi

    if [[ "$current_uid" != "$PUID" ]]; then
        usermod -u "$PUID" "$USERNAME"
    fi
fi

mkdir -p \
    /workspace \
    /home/opencode/.config/opencode \
    /home/opencode/.local/share/opencode \
    /home/opencode/.cache \
    /home/opencode/.cargo \
    /home/opencode/.npm \
    /home/opencode/.config/gh

# Fix the small home/state tree, but do not recursively scan a potentially
# large bind-mounted workspace.
chown -R "$PUID:$PGID" /home/opencode
chown "$PUID:$PGID" /workspace 2>/dev/null || true

export HOME=/home/opencode
export USER="$USERNAME"
export LOGNAME="$USERNAME"
export CARGO_HOME=/home/opencode/.cargo

# Numeric execution works whether the IDs map to opencode, an existing
# platform account such as nobody:users, or no named account at all.
exec su-exec "${PUID}:${PGID}" "$@"
