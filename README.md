# Deer Detection ECU

Thermal camera-based deer detection for Honda Civic.
Target: Jetson Orin Nano Super Dev Kit · JetPack 7.2.1 / L4T R39.2.1.

## Repo layout
- `docker/` - Yocto build-host image (Ubuntu 24.04-based; on 22.04 hosts, swap the `python3-websockets` apt line for `pip3 install 'websockets>=10'` in the Dockerfile)
- `docs/` - Build environment reference, roadmap, layer pins
- `kas/` - Pinned reproducible builds (Phase 6)
- `meta-deer/` - Product layer (Phase 5)

## Quick start
See `docs/BUILD-ENVIRONMENT.md` and `docs/yocto-jetson-roadmap-r39-v2.md`.
