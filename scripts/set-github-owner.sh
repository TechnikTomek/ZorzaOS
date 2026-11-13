#!/usr/bin/env bash
# Wstawia Twój login GitHub do linków i odznak projektu.
# Użycie: scripts/set-github-owner.sh <login> [nazwa-repozytorium]
set -euo pipefail
OWNER="${1:?Podaj login GitHub, np.: scripts/set-github-owner.sh jankowalski}"
REPO="${2:-zorza-os}"
cd "$(dirname "$0")/.."
FILES=$(grep -rl "zorza-os/zorza-os\|zorza-os\.github\.io" --exclude-dir=.git --exclude-dir=out --exclude-dir=dist --exclude-dir=work . || true)
for f in $FILES; do
  sed -i.bak -e "s#zorza-os/zorza-os#$OWNER/$REPO#g" -e "s#zorza-os\.github\.io/zorza-os#$OWNER.github.io/$REPO#g" "$f" && rm -f "$f.bak"
done
echo "Gotowe: linki wskazują na https://github.com/$OWNER/$REPO"
