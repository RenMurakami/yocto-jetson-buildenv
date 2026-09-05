#!/usr/bin/env bash
# Create a user matching the host UID/GID, install the shared site.conf, drop privileges.
set -euo pipefail

HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"
USER_NAME="${USER_NAME:-yocto}"

# group
if ! getent group "$HOST_GID" >/dev/null; then
    groupadd -g "$HOST_GID" "$USER_NAME"
fi

# user (reuse if the UID already exists)
if ! getent passwd "$HOST_UID" >/dev/null; then
    useradd -m -u "$HOST_UID" -g "$HOST_GID" -s /bin/bash "$USER_NAME"
fi
USER_NAME="$(getent passwd "$HOST_UID" | cut -d: -f1)"
HOME_DIR="$(getent passwd "$HOST_UID" | cut -d: -f6)"

# password-less sudo: convenient inside a disposable container
mkdir -p /etc/sudoers.d
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-yocto
chmod 0440 /etc/sudoers.d/90-yocto

# tegra-demo-distro's setup-env auto-links ~/.yocto/site.conf into build/conf/site.conf.
# That is how the shared caches get into every build dir without editing anything.
mkdir -p "$HOME_DIR/.yocto"
if [ ! -e "$HOME_DIR/.yocto/site.conf" ]; then
    cp /opt/yocto/site.conf "$HOME_DIR/.yocto/site.conf"
fi
chown "$HOST_UID:$HOST_GID" "$HOME_DIR"
chown -R "$HOST_UID:$HOST_GID" "$HOME_DIR/.yocto"

# shared caches + /work (bind-mounted from the host by yocto-shell.sh; create if running bare).
# Non-recursive chown: makes the bare case writable, and is a no-op on a correctly owned bind mount.
mkdir -p /work /srv/yocto/downloads /srv/yocto/sstate-cache
chown "$HOST_UID:$HOST_GID" /work /srv/yocto/downloads /srv/yocto/sstate-cache

export HOME="$HOME_DIR" USER="$USER_NAME" LOGNAME="$USER_NAME"
exec setpriv --reuid="$HOST_UID" --regid="$HOST_GID" --init-groups -- "$@"
