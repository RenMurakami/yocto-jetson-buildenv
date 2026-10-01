# Yocto build host for the Deer Detection ECU
# Target: Jetson Orin Nano Super Dev Kit, meta-tegra "wrynose" (L4T R39.2.1 / JetPack 7.2.1)
# Base: Ubuntu 24.04 LTS - on the Yocto 6.0 "wrynose" supported-distribution list.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# Official Yocto 6.0 Ubuntu/Debian package list, verbatim, minus python3-websockets
# (docs.yoctoproject.org/6.0/ref-manual/system-requirements.html) - the archive
# version is too old, so it comes from pip on the next line instead.
RUN apt-get update && apt-get install -y \
    build-essential chrpath cpio debianutils diffstat file gawk gcc git \
    iputils-ping libacl1 libcrypt-dev locales python3 python3-git \
    python3-jinja2 python3-pexpect python3-pip python3-subunit socat \
    texinfo unzip wget xz-utils zstd \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir --break-system-packages 'websockets>=10'

# OE4T flashing prerequisites (oe4t.github.io/wrynose/Flashing.html) so a tegraflash
# tarball can be unpacked and inspected in here. Real flashing still happens on the
# native Linux flash host - never from WSL2/Docker.
RUN apt-get update && apt-get install -y \
    bash device-tree-compiler cpp gdisk udisks2 bmap-tools usbutils libxml2-utils \
 && rm -rf /var/lib/apt/lists/*

# Tools a desktop has but a bare container lacks, plus conveniences
RUN apt-get update && apt-get install -y \
    bzip2 gzip tar patch diffutils findutils make procps iproute2 \
    ca-certificates curl lz4 python3-venv \
    git-lfs sudo tmux screen vim-tiny less rsync picocom \
 && rm -rf /var/lib/apt/lists/*

# BitBake requires en_US.UTF-8. Generate it the non-interactive way the Yocto docs prescribe.
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

# kas: reproducible layer checkout + build driver (used for CI later; harmless now)
RUN pip3 install --no-cache-dir --break-system-packages kas

# Ubuntu 24.04 images ship a default "ubuntu" user with UID 1000. Remove it so the
# entrypoint can create a user with YOUR host UID/GID (usually also 1000) cleanly.
RUN userdel -r ubuntu 2>/dev/null || true

# Layout: /work = your ~/yocto (bind mount), /srv/yocto/* = shared caches (bind mounts)
RUN mkdir -p /work /srv/yocto/downloads /srv/yocto/sstate-cache /opt/yocto
COPY site.conf /opt/yocto/site.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
