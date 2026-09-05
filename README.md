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
| `docker/site.conf` | Copied to `~/.yocto/site.conf`; `tegra-demo-distro`'s `setup-env` auto-links it into every build directory (shared `DL_DIR`/`SSTATE_DIR`, extra `IMAGE_FSTYPES`) |
| `docker/yocto-shell.sh` | One command to enter the container with your UID/GID and the persistent caches bind-mounted |
| `docs/BUILD-ENVIRONMENT.md` | Authoritative host/flash-host requirements (disk, RAM, packages, tool versions, locale, checklist) |
| `docs/yocto-jetson-roadmap-r39-v2.md` | Full build-to-flash roadmap (§0 build host, Phase 1–7); referenced by consuming projects |
| `docs/layer-pins-wrynose.md` | Exact `tegra-demo-distro` submodule commits at the time of the last M0 verification |
| `kas/` | Reserved for reproducible kas configurations (added once a consuming project needs CI) |

## Quick start

Full instructions in `docs/BUILD-ENVIRONMENT.md`. Short version:

```bash
git clone <this-repo> && cd yocto-jetson-buildenv
docker build -t yocto-jetson:wrynose docker/
mkdir -p ~/yocto && cd ~/yocto
sudo mkdir -p /srv/yocto/{downloads,sstate-cache} && sudo chown -R "$USER" /srv/yocto
/path/to/yocto-jetson-buildenv/docker/yocto-shell.sh      # → prompt inside the container, cwd = ~/yocto
```

Then verify with the M0 checklist in `docs/BUILD-ENVIRONMENT.md` §9.

## Notes for specific hosts

- **Ubuntu 22.04 build host:** the Yocto docs require a newer `python3-websockets` than apt provides on 22.04. In the Dockerfile, remove `python3-websockets` from the apt list and install it via pip instead: `RUN pip3 install --no-cache-dir --break-system-packages 'websockets>=10'`.
- **Windows 11 + WSL2:** keep sources and caches on the WSL ext4 filesystem (`~` and `/srv/yocto`), never under `/mnt/c` (slow and case-insensitive).

## Consuming projects

Product-specific layers (`meta-<product>`), applications, DBCs, vehicle notes, and CI live in their own repositories. Each consumer clones this repo alongside its own tree and points `yocto-shell.sh` at it. Current consumers:

- Deer detection ECU (Honda Civic thermal-camera project) — private
