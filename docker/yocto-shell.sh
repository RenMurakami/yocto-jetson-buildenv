#!/usr/bin/env bash
# Enter the Yocto build container with your UID/GID and the persistent caches mounted.
#   docker/yocto-shell.sh              -> interactive shell; cwd = /work = the directory you ran it from
#   docker/yocto-shell.sh <command...> -> run one command and exit
set -euo pipefail

IMAGE="${YOCTO_IMAGE:-yocto-jetson:wrynose}"
WORK="${YOCTO_WORK:-$PWD}"
CACHE="${YOCTO_CACHE:-/srv/yocto}"

mkdir -p "$CACHE/downloads" "$CACHE/sstate-cache"

# A terminal (-t) only when there is one.  Scripts that run a command through
# this file (e.g. meta-sloth/scripts/sloth-pipeline) capture its output, and
# docker refuses -t when stdin is not a terminal.
tty=()
if [ -t 0 ] && [ -t 1 ]; then
  tty=(-t)
fi

exec docker run --rm -i "${tty[@]}" \
  --hostname yocto-build \
  -e HOST_UID="$(id -u)" \
  -e HOST_GID="$(id -g)" \
  -e USER_NAME="$(id -un)" \
  -e http_proxy -e https_proxy -e no_proxy \
  -v "$WORK":/work \
  -v "$CACHE/downloads":/srv/yocto/downloads \
  -v "$CACHE/sstate-cache":/srv/yocto/sstate-cache \
  -w /work \
  "$IMAGE" "$@"
