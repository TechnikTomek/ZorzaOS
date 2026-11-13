#!/usr/bin/env bash
# =============================================================================
#  Zorza OS – konfiguracja live-build dla danej architektury.
#  Wywoływane z katalogu roboczego (WORK/<arch>).
#  Użycie: lb-config.sh <arch> <katalog-źródeł> <katalog-grafik>
# =============================================================================
set -euo pipefail
ARCH="$1"; SRC="$2"; ASSETS="$3"
# shellcheck source=/dev/null
. "$SRC/zorza.conf"

MIRROR="${ZORZA_MIRROR:-https://deb.debian.org/debian}"
MIRROR_SEC="${ZORZA_MIRROR_SECURITY:-https://deb.debian.org/debian-security}"
SQUASH="${ZORZA_SQUASHFS:-xz}"

case "$ARCH" in
  amd64)
    BOOTLOADERS="grub-pc,grub-efi"   # BIOS + UEFI w jednym hybrydowym ISO
    FLAVOUR="amd64"
    SECUREBOOT="enable"
    ;;
  arm64)
    BOOTLOADERS="grub-efi"           # Apple Silicon / VirtualBox ARM: tylko UEFI
    FLAVOUR="arm64"
    SECUREBOOT="disable"
    ;;
  *) echo "Nieznana architektura: $ARCH"; exit 1 ;;
esac

VOL="ZORZA_${ZORZA_VERSION//./_}_${ARCH^^}"

lb config noauto \
  --mode debian \
  --system live \
  --distribution "$ZORZA_DEBIAN_SUITE" \
  --architecture "$ARCH" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap "$MIRROR" \
  --mirror-chroot "$MIRROR" \
  --mirror-chroot-security "$MIRROR_SEC" \
  --mirror-binary "https://deb.debian.org/debian" \
  --mirror-binary-security "https://deb.debian.org/debian-security" \
  --security true \
  --updates true \
  --apt-recommends true \
  --apt-indices true \
  --cache-packages true \
  --linux-flavours "$FLAVOUR" \
  --firmware-chroot false \
  --firmware-binary false \
  --debian-installer none \
  --binary-image iso-hybrid \
  --bootloaders "$BOOTLOADERS" \
  --uefi-secure-boot "$SECUREBOOT" \
  --memtest none \
  --win32-loader false \
  --checksums sha256 \
  --chroot-squashfs-compression-type "$SQUASH" \
  --iso-application "$ZORZA_NAME $ZORZA_VERSION" \
  --iso-publisher "$ZORZA_NAME Project" \
  --iso-preparer "zorza build.command (live-build)" \
  --iso-volume "$VOL" \
  --image-name "$ZORZA_ID-$ARCH" \
  --hdd-label "ZORZA" \
  --bootappend-live "boot=live components quiet splash username=live hostname=zorza user-fullname=Live timezone=Europe/Warsaw" \
  --bootappend-live-failsafe "none"

# --- Własne pliki konfiguracyjne -------------------------------------------
cp -a "$SRC/config/." config/

# Parametry wydania dostępne dla hooków w chroocie
mkdir -p config/includes.chroot/etc
cp "$SRC/zorza.conf" config/includes.chroot/etc/zorza-release.conf

# --- Grafiki wygenerowane skryptem -------------------------------------------
# assets/chroot/** → system plików live, assets/grub/** → motyw GRUB
cp -a "$ASSETS/chroot/." config/includes.chroot/
mkdir -p config/bootloaders/grub-pc
cp -a "$ASSETS/grub/." config/bootloaders/grub-pc/

# Ten sam motyw GRUB dla zainstalowanego systemu
mkdir -p config/includes.chroot/usr/share/grub/themes/zorza
cp -a "$ASSETS/grub/zorza/." config/includes.chroot/usr/share/grub/themes/zorza/
cp "$SRC/config/bootloaders/grub-pc/zorza/theme.txt" config/includes.chroot/usr/share/grub/themes/zorza/theme.txt
sed -i "s/@ZORZA_VERSION@/$ZORZA_VERSION/g; s/@ZORZA_ARCH@/$ARCH/g" config/includes.chroot/usr/share/grub/themes/zorza/theme.txt

# Plik konfiguracyjny GRUB: podstawiamy wersję
sed -i "s/@ZORZA_VERSION@/$ZORZA_VERSION/g; s/@ZORZA_ARCH@/$ARCH/g" config/bootloaders/grub-pc/*.cfg config/bootloaders/grub-pc/zorza/theme.txt
