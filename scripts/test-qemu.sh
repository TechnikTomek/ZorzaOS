#!/usr/bin/env bash
# =============================================================================
#  Zorza OS – test rozruchu w QEMU (headless) ze zrzutami ekranu.
#  Użycie: scripts/test-qemu.sh <plik.iso> [uefi|bios] [sekundy] [katalog-zrzutów]
#  ISO z „arm64” w nazwie uruchamia się w qemu-system-aarch64 (virt + UEFI).
#  Grafika: domyślnie -vga std (OVMF w QEMU nie ma sterownika GOP dla VMware SVGA);
#  ZORZA_VGA=vmware testuje sterownik vmwgfx (jak VMSVGA w VirtualBox) w trybie BIOS.
#  Zrzut co 30 s trafia do katalogu zrzutów (PNG, jeśli jest ImageMagick/Python PIL).
# =============================================================================
set -euo pipefail
ISO="${1:?Podaj ścieżkę do ISO}"
MODE="${2:-uefi}"
DURATION="${3:-900}"
SHOTS="${4:-out/screenshots}"
mkdir -p "$SHOTS"
TMP="$(mktemp -d)"
trap 'echo quit | socat - UNIX-CONNECT:"$TMP/mon" >/dev/null 2>&1 || true; kill $QPID 2>/dev/null || true; rm -rf "$TMP"' EXIT

ARCH=amd64
case "$(basename "$ISO")" in *arm64*) ARCH=arm64 ;; esac

if [ "$ARCH" = arm64 ]; then
  # Apple Silicon / VirtualBox ARM: maszyna virt + UEFI (AAVMF), grafika virtio-gpu
  ACCEL="-accel tcg,thread=multi -cpu max"
  [ -w /dev/kvm ] && [ "$(uname -m)" = aarch64 ] && ACCEL="-accel kvm -cpu host"
  cp /usr/share/AAVMF/AAVMF_VARS.fd "$TMP/vars.fd"
  qemu-system-aarch64 $ACCEL -machine virt -m 4096 -smp 4 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/AAVMF/AAVMF_CODE.fd \
    -drive if=pflash,format=raw,file="$TMP/vars.fd" \
    -device virtio-scsi-pci,id=scsi -drive if=none,id=cd,media=cdrom,readonly=on,file="$ISO" \
    -device scsi-cd,drive=cd,bus=scsi.0 \
    -device virtio-gpu-pci -display none -vnc 127.0.0.1:7 \
    -device qemu-xhci -device usb-kbd -device usb-tablet \
    -nic user,model=virtio-net-pci \
    -audiodev none,id=noaudio \
    -monitor unix:"$TMP/mon",server,nowait \
    -serial file:"$SHOTS/serial.log" &
else
  ACCEL="-accel tcg,thread=multi"
  [ -w /dev/kvm ] && ACCEL="-accel kvm -cpu host"
  FW=()
  if [ "$MODE" = uefi ]; then
    cp /usr/share/OVMF/OVMF_VARS_4M.fd "$TMP/vars.fd"
    FW=(-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
        -drive if=pflash,format=raw,file="$TMP/vars.fd")
  fi
  qemu-system-x86_64 $ACCEL -machine q35 -m 4096 -smp 4 ${FW[@]+"${FW[@]}"} \
    -cdrom "$ISO" -boot d \
    -vga "${ZORZA_VGA:-std}" -display none -vnc 127.0.0.1:7 \
    -device qemu-xhci -device usb-tablet \
    -nic user,model=virtio-net-pci \
    -audiodev none,id=noaudio \
    -monitor unix:"$TMP/mon",server,nowait \
    -serial file:"$SHOTS/serial.log" &
fi
QPID=$!

shot() {
  local name="$1"
  echo "screendump $TMP/s.ppm" | socat - UNIX-CONNECT:"$TMP/mon" >/dev/null 2>&1 || return 0
  sleep 1
  python3 -c "from PIL import Image; Image.open('$TMP/s.ppm').save('$SHOTS/$name.png')" 2>/dev/null \
    || cp "$TMP/s.ppm" "$SHOTS/$name.ppm"
  echo "[test] zrzut $SHOTS/$name.png"
}

t=0
while [ $t -lt "$DURATION" ] && kill -0 $QPID 2>/dev/null; do
  sleep 30; t=$((t + 30))
  shot "$(printf 't%04d' $t)"
done
shot final
