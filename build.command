#!/usr/bin/env bash
# =============================================================================
#  Zorza OS – główny skrypt budowania
#  Użycie:  ./build.command amd64|arm64|all [--native] [--clean]
#           albo dwuklik w Finderze / bez argumentów – pojawi się menu
#  Wynik:   out/zorza-<wersja>-<arch>.iso  +  out/SHA256SUMS
#
#  Działa na Linuksie, macOS (Docker Desktop / OrbStack / Colima) i w WSL2.
#  Budowanie odbywa się w uprzywilejowanym kontenerze Debian 13 (trixie).
#
#  Zmienne środowiskowe (opcjonalne):
#    ZORZA_EXTRA_CA=/ścieżka/ca.crt  – dodatkowy certyfikat CA (proxy z inspekcją TLS)
#    https_proxy / HTTPS_PROXY       – proxy HTTP(S), przekazywane do kontenera
#    ZORZA_SQUASHFS=zstd|xz          – kompresja systemu plików (domyślnie xz)
#    ZORZA_MIRROR=https://...        – mirror Debiana (domyślnie deb.debian.org)
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"
# shellcheck source=/dev/null
. "$HERE/zorza.conf"

usage() { echo "Użycie: $0 amd64|arm64|all [--native] [--clean]"; exit 1; }

log() { printf '\033[1;35m[zorza]\033[0m %s\n' "$*"; }

# --- Uruchomienie dwuklikiem (bez argumentów): krótkie menu -----------------
INTERACTIVE=0
if [ $# -eq 0 ]; then
  [ -t 0 ] || usage
  INTERACTIVE=1
  # Okno Terminala nie zamknie się, zanim przeczytasz wynik
  trap 'echo; read -r -p "Naciśnij Enter, aby zamknąć okno…" _' EXIT
  case "$(uname -m)" in
    arm64|aarch64) DEF=2 ;;
    *) DEF=1 ;;
  esac
  echo
  echo "  Zorza OS $ZORZA_VERSION – budowanie obrazu ISO"
  echo "  ─────────────────────────────────────────"
  echo "  1) amd64  – PC z Intel/AMD, VirtualBox na Windows"
  echo "  2) arm64  – Mac z Apple Silicon (VirtualBox 7.1+)"
  echo "  3) oba"
  echo
  read -r -p "  Wybierz [1-3] (Enter = $DEF): " CHOICE
  CHOICE="${CHOICE:-$DEF}"
  case "$CHOICE" in
    1) set -- amd64 ;;
    2) set -- arm64 ;;
    3) set -- all ;;
    *) echo "Nieprawidłowy wybór: $CHOICE"; exit 1 ;;
  esac
fi

TARGET="$1"; shift
NATIVE=0; CLEAN=0
for a in "$@"; do
  case "$a" in
    --native) NATIVE=1 ;;
    --clean)  CLEAN=1 ;;
    *) usage ;;
  esac
done

case "$TARGET" in
  amd64|arm64) ARCHES="$TARGET" ;;
  all)         ARCHES="amd64 arm64" ;;
  *) usage ;;
esac

mkdir -p out
PROXY="${https_proxy:-${HTTPS_PROXY:-}}"

if [ "$NATIVE" = 1 ]; then
  # Bez Dockera – tylko na hoście Debian 13 z zainstalowanym live-build (np. w CI).
  [ "$(id -u)" = 0 ] || { echo "Tryb --native wymaga roota (sudo)."; exit 1; }
  for arch in $ARCHES; do
    ZORZA_WORK="${ZORZA_WORK:-$HERE/work}" ZORZA_CLEAN=$CLEAN "$HERE/scripts/container-build.sh" "$arch"
  done
else
  command -v docker >/dev/null || { echo "Brak Dockera. Zainstaluj Docker Desktop: https://www.docker.com/products/docker-desktop/"; exit 1; }
  if ! docker info >/dev/null 2>&1; then
    if [ "$(uname -s)" = Darwin ] && [ -d /Applications/Docker.app ]; then
      log "Uruchamiam Docker Desktop…"
      open -a Docker
      for _ in $(seq 1 90); do docker info >/dev/null 2>&1 && break; sleep 2; done
    fi
    docker info >/dev/null 2>&1 || { echo "Docker nie działa. Uruchom Docker Desktop i spróbuj ponownie."; exit 1; }
  fi

  if [ -n "${ZORZA_EXTRA_CA:-}" ]; then
    cp "$ZORZA_EXTRA_CA" docker/certs/extra-ca.crt
  fi

  NET_ARGS=()
  ENV_ARGS=(-e "ZORZA_CLEAN=$CLEAN" -e "ZORZA_RESUME=${ZORZA_RESUME:-0}" -e "ZORZA_SQUASHFS=${ZORZA_SQUASHFS:-}" -e "ZORZA_MIRROR=${ZORZA_MIRROR:-}")
  BUILD_ARGS=()
  if [ -n "$PROXY" ]; then
    # Proxy na localhoście hosta jest widoczne tylko z sieci hosta.
    NET_ARGS=(--network host)
    ENV_ARGS+=(-e "https_proxy=$PROXY" -e "HTTPS_PROXY=$PROXY")
    BUILD_ARGS=(--network host --build-arg "https_proxy=$PROXY" --build-arg "http_proxy=$PROXY")
  fi

  log "Buduję obraz kontenera zorza-builder…"
  docker build ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"} -t zorza-builder:latest "$HERE"

  for arch in $ARCHES; do
    log "Buduję ISO dla $arch (to potrwa – zwykle 30–90 min)…"
    # Katalog roboczy na wolumenie Dockera: szybciej i bez problemów z
    # uprawnieniami/urządzeniami na macOS i Windows.
    docker run --rm --privileged ${NET_ARGS[@]+"${NET_ARGS[@]}"} "${ENV_ARGS[@]}" \
      -v "$HERE":/build \
      -v "zorza-work-$arch":/work \
      -e ZORZA_WORK=/work \
      zorza-builder:latest "$arch"
  done
fi

if command -v sha256sum >/dev/null; then SUM="sha256sum"; else SUM="shasum -a 256"; fi
( cd out && $SUM ./*.iso | sed 's# \./# #' > SHA256SUMS )
log "Gotowe:"; ls -lh out/
