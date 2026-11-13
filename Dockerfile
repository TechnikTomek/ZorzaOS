# Zorza OS – środowisko budowania obrazów ISO (Debian 13 trixie + live-build)
FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8

# Opcjonalne certyfikaty CA (np. firmowy proxy z inspekcją TLS): docker/certs/*.crt
COPY docker/certs/ /usr/local/share/ca-certificates/zorza-extra/

RUN set -e; \
    ca="$(ls /usr/local/share/ca-certificates/zorza-extra/*.crt 2>/dev/null | head -n1 || true)"; \
    opt=""; \
    if [ -n "$ca" ]; then \
        sed -i 's#http://#https://#g' /etc/apt/sources.list.d/debian.sources; \
        opt="-o Acquire::https::CaInfo=$ca"; \
    fi; \
    apt-get $opt update; \
    apt-get $opt install -y --no-install-recommends \
        live-build debootstrap debian-archive-keyring ca-certificates curl \
        xorriso squashfs-tools mtools dosfstools cpio zstd xz-utils \
        isolinux syslinux-common \
        grub-common \
        qemu-user-static binfmt-support \
        python3 python3-numpy python3-pil librsvg2-bin fonts-inter fonts-dejavu-core \
        rsync git file procps; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
ENTRYPOINT ["bash", "/build/scripts/container-build.sh"]
