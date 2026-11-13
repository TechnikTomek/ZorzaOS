#!/usr/bin/env bash
# =============================================================================
#  Zorza OS – budowanie jednej architektury (uruchamiane w kontenerze
#  zorza-builder albo natywnie na Debianie 13 jako root).
#  Użycie: container-build.sh amd64|arm64
# =============================================================================
set -euo pipefail

ARCH="${1:?Podaj architekturę: amd64|arm64}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${ZORZA_WORK:-$SRC/work}"
WORK="$WORK_ROOT/$ARCH"
OUT="$SRC/out"
# shellcheck source=/dev/null
. "$SRC/zorza.conf"

log() { printf '\033[1;35m[zorza:%s]\033[0m %s\n' "$ARCH" "$*"; }

HOST_ARCH="$(dpkg --print-architecture)"
PROXY="${https_proxy:-${HTTPS_PROXY:-}}"

# --- 1. Emulacja obcej architektury (np. arm64 na x86_64) ---------------------
if [ "$ARCH" != "$HOST_ARCH" ]; then
  log "Host: $HOST_ARCH, cel: $ARCH → włączam qemu-user-static (binfmt_misc)"
  [ -d /proc/sys/fs/binfmt_misc ] || mkdir -p /proc/sys/fs/binfmt_misc
  mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
  # Rejestracja statycznego emulatora z flagą F (interpreter otwierany od razu,
  # działa także wewnątrz chroota). Format: :nazwa:M::magic:maska:interpreter:flagi
  case "$ARCH" in
    arm64)
      QNAME=qemu-aarch64; QBIN=/usr/bin/qemu-aarch64-static
      MAGIC='\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00'
      MASK='\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff' ;;
    amd64)
      QNAME=qemu-x86_64; QBIN=/usr/bin/qemu-x86_64-static
      MAGIC='\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'
      MASK='\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff' ;;
  esac
  if [ -e "/proc/sys/fs/binfmt_misc/$QNAME" ] && ! grep -q "^interpreter $QBIN" "/proc/sys/fs/binfmt_misc/$QNAME"; then
    echo -1 > "/proc/sys/fs/binfmt_misc/$QNAME" 2>/dev/null || true
  fi
  if [ ! -e "/proc/sys/fs/binfmt_misc/$QNAME" ]; then
    printf ':%s:M::%s:%s:%s:F\n' "$QNAME" "$MAGIC" "$MASK" "$QBIN" > /proc/sys/fs/binfmt_misc/register
  fi
  log "binfmt: $(grep -E '^(interpreter|flags)' "/proc/sys/fs/binfmt_misc/$QNAME" | tr '\n' ' ')"
fi

# --- 2. Grafiki (tapety, logo, motywy) – renderowane skryptami --------------
ASSETS="$WORK_ROOT/assets"
log "Renderuję grafiki do $ASSETS"
python3 "$SRC/scripts/render-assets.py" "$SRC" "$ASSETS"

# Plik konfiguracyjny Flathub (zawiera klucz GPG repozytorium)
FLATHUB="$WORK_ROOT/flathub.flatpakrepo"
if [ ! -s "$FLATHUB" ]; then
  curl -fsSL --retry 3 -o "$FLATHUB" https://dl.flathub.org/repo/flathub.flatpakrepo \
    || { log "UWAGA: nie pobrano flathub.flatpakrepo – Flathub trzeba będzie dodać ręcznie"; : > "$FLATHUB"; }
fi

# --- 3. Przygotowanie drzewa live-build ----------------------------------------
if [ "${ZORZA_CLEAN:-0}" = 1 ] && [ -d "$WORK" ]; then
  log "Czyszczę $WORK"
  ( cd "$WORK" && lb clean --purge >/dev/null 2>&1 || true )
  rm -rf "$WORK"
fi
mkdir -p "$WORK"
cd "$WORK"
if [ "${ZORZA_RESUME:-0}" = 1 ] && [ -d .build ]; then
  log "Wznawiam przerwany build (ZORZA_RESUME=1) – pomijam ukończone etapy"
elif [ -d .build ]; then
  # Szybka przebudowa: zachowujemy cache pakietów i bootstrapu,
  # ale chroot i binary budujemy od nowa.
  lb clean --chroot --binary --stage >/dev/null 2>&1 || lb clean >/dev/null 2>&1 || true
  rm -rf .build chroot binary
fi
if [ "${ZORZA_RESUME:-0}" != 1 ] || [ ! -d config ]; then
rm -rf config
bash "$SRC/scripts/lb-config.sh" "$ARCH" "$SRC" "$ASSETS"
# Bity wykonywalności mogą zginąć przy rozpakowaniu ZIP – przywracamy je
chmod +x config/hooks/normal/*.hook.chroot config/includes.chroot/usr/bin/* \
  config/includes.chroot/usr/lib/zorza/*.sh config/includes.chroot/usr/lib/zorza/*.py \
  config/includes.chroot/usr/lib/live/config/* 2>/dev/null || true
mkdir -p config/includes.chroot/usr/share/zorza
cp "$FLATHUB" config/includes.chroot/usr/share/zorza/flathub.flatpakrepo
fi

# --- 4. Tymczasowy dostęp do sieci przez proxy / własne CA (tylko build) -----
EXTRA_CA="$(ls /usr/local/share/ca-certificates/zorza-extra/*.crt 2>/dev/null | head -n1 || true)"
inject_build_net() {
  local root="$1"
  [ -n "$EXTRA_CA$PROXY" ] || return 0
  mkdir -p "$root/etc/apt/apt.conf.d" "$root/usr/local/share"
  : > "$root/etc/apt/apt.conf.d/00zorza-build-net"
  if [ -n "$EXTRA_CA" ]; then
    cp "$EXTRA_CA" "$root/usr/local/share/zorza-build-ca.crt"
    echo 'Acquire::https::CaInfo "/usr/local/share/zorza-build-ca.crt";' >> "$root/etc/apt/apt.conf.d/00zorza-build-net"
  fi
  if [ -n "$PROXY" ]; then
    echo "Acquire::https::Proxy \"$PROXY\";" >> "$root/etc/apt/apt.conf.d/00zorza-build-net"
    echo "Acquire::http::Proxy \"$PROXY\";"  >> "$root/etc/apt/apt.conf.d/00zorza-build-net"
  fi
}
if [ -n "$EXTRA_CA$PROXY" ]; then
  # Te pliki nigdy nie trafią do squashfs (patrz config/rootfs/excludes).
  mkdir -p config/rootfs
  printf '%s\n' etc/apt/apt.conf.d/00zorza-build-net usr/local/share/zorza-build-ca.crt >> config/rootfs/excludes
  export ZORZA_BUILD_PROXY="$PROXY"
fi

# --- 5. Budowanie --------------------------------------------------------------
log "lb bootstrap"
lb bootstrap 2>&1 | tee -a build.log
inject_build_net chroot
log "lb chroot"
lb chroot 2>&1 | tee -a build.log
inject_build_net chroot
log "lb binary"
# binary_chroot zastępuje chroot kopią bootstrapu z cache – wstrzykujemy
# ponownie tymczasową konfigurację sieci zanim live-build doinstaluje narzędzia.
lb binary_chroot 2>&1 | tee -a build.log
inject_build_net chroot
lb binary 2>&1 | tee -a build.log

ISO_SRC="$(ls -1 "$WORK"/*.iso 2>/dev/null | head -n1 || true)"
[ -n "$ISO_SRC" ] || { log "BŁĄD: nie powstał plik ISO – zobacz $WORK/build.log"; exit 1; }

mkdir -p "$OUT"
ISO_DST="$OUT/${ZORZA_ID}-${ZORZA_VERSION}-${ARCH}.iso"
cp -f "$ISO_SRC" "$ISO_DST"
( cd "$OUT" && sha256sum "$(basename "$ISO_DST")" > "$(basename "$ISO_DST").sha256" )
# Lista pakietów z bazy dpkg pełnego systemu live
dpkg-query --admindir="$WORK/chroot/var/lib/dpkg" -W -f '${Package}\t${Version}\n' \
  > "$OUT/${ZORZA_ID}-${ZORZA_VERSION}-${ARCH}.packages" 2>/dev/null || true
log "Gotowe: $ISO_DST ($(du -h "$ISO_DST" | cut -f1))"
