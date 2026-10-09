# yocto-jetson-buildenv

Reproducible Yocto build environment for NVIDIA Jetson targets, packaged as a Docker image.
Any Jetson project can consume this — it does not carry product-specific code or configuration.

- **Yocto release:** 6.0 "wrynose"
- **BSP:** OE4T `meta-tegra` `wrynose` → **Jetson Linux R39.2.1 / JetPack 7.2.1**
- **Currently exercised on:** Jetson Orin Nano Super Dev Kit
- **Build host:** Ubuntu 24.04 LTS inside Docker (works from Linux, WSL2, macOS)
- **Flash host:** native x86-64 Linux only (never WSL2 / VM / Docker Desktop)

## What is in here

| Path | Purpose |
|---|---|
| `docker/Dockerfile` | Ubuntu 24.04 + the official Yocto 6.0 package list + OE4T flash prerequisites + kas |
| `docker/entrypoint.sh` | Creates a user matching your host UID/GID at container start; bitbake refuses to run as root |
| `docker/site.conf` | Copied to `~/.yocto/site.conf`; `tegra-demo-distro`'s `setup-env` auto-links it into every build directory (shared `DL_DIR`/`SSTATE_DIR`, hash-equivalence DB, extra `IMAGE_FSTYPES`) |
| `docker/yocto-shell.sh` | One command to enter the container with your UID/GID and the persistent caches bind-mounted |
| `docs/layer-pins-wrynose.md` | Exact `tegra-demo-distro` submodule commits at the time of the last M0 verification |
| `kas/` | Reserved for reproducible kas configurations (added once a consuming project needs CI) |

## Requirements

| | |
|---|---|
| Disk | ~250 GB per build tree, plus the shared caches (currently ~66 GB) |
| RAM | 16 GB minimum, 32 GB comfortable |
| Host packages | Docker only — everything else lives in the image |
| Caches | `/srv/yocto/downloads` and `/srv/yocto/sstate-cache`, owned by your user |

Keep the build tree and the caches on a native Linux filesystem. On WSL2 that
means under `~` and `/srv`, never `/mnt/c`.

## Quick start

```bash
git clone <this-repo> && cd yocto-jetson-buildenv
docker build -t yocto-jetson:wrynose docker/
mkdir -p ~/yocto && cd ~/yocto
sudo mkdir -p /srv/yocto/{downloads,sstate-cache} && sudo chown -R "$USER" /srv/yocto
/path/to/yocto-jetson-buildenv/docker/yocto-shell.sh      # → prompt inside the container, cwd = ~/yocto
```

`yocto-shell.sh` bind-mounts the directory you run it from as `/work`, so run it
from the top of your build tree — not from inside `docker/`.

It honours three environment variables: `YOCTO_IMAGE` (default
`yocto-jetson:wrynose`), `YOCTO_WORK` (default `$PWD`) and `YOCTO_CACHE`
(default `/srv/yocto`).

### Verifying the container

Inside the container, all four of these should hold:

```bash
id                                   # your host UID/GID, not root
echo $LANG                           # en_US.UTF-8 - bitbake requires it
cat ~/.yocto/site.conf               # installed by the entrypoint
touch /srv/yocto/downloads/.w && rm /srv/yocto/downloads/.w   # caches writable
```

`bitbake` is not on `PATH` until you source a build tree's `setup-env`; `kas` is
at `/usr/local/bin/kas`.

## Notes

- **`websockets`:** the Yocto 6.0 package list calls for `python3-websockets`,
  but the version in Ubuntu's archive is too old. The Dockerfile installs it
  with pip (`'websockets>=10'`) instead, unconditionally, so this works the same
  on any Ubuntu base.
- **`site.conf` changes require an image rebuild.** It is baked into the image at
  `/opt/yocto/site.conf` and copied to `~/.yocto/site.conf` on every container
  start. Editing the repo copy alone changes nothing until you re-run
  `docker build`.
- **Windows 11 + WSL2:** keep sources and caches on the WSL ext4 filesystem
  (`~` and `/srv/yocto`), never under `/mnt/c` (slow and case-insensitive).

## Consuming projects

Product-specific layers (`meta-<product>`), applications, DBCs, vehicle notes,
and CI live in their own repositories. Each consumer clones this repo alongside
its own tree and points `yocto-shell.sh` at it. Current consumers:

- **Sloth** (Honda Civic thermal-camera deer detection ECU) — `meta-sloth`, private.
  Provides the `sloth` distro, the `sloth-orin-nano-sd` machine and the images;
  consumes this repo for the container and the shared caches.
