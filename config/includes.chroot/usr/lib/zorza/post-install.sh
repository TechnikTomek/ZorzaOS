#!/bin/sh
# Zorza OS – porządki po instalacji (Calamares, wewnątrz zainstalowanego systemu)
set -e
# Pozostałości sesji live
rm -f /etc/sddm.conf.d/90-zorza-live.conf /etc/sudoers.d/90-zorza-live
rm -f /usr/lib/live/config/1190-zorza-live
rm -f /usr/share/applications/zorza-install.desktop
# Pierwsze uruchomienie: aplikacja Witaj pokaże się nowemu użytkownikowi
for home in /home/*; do
  [ -d "$home" ] || continue
  rm -f "$home/.config/zorza/welcome-done"
  rm -f "$home"/Desktop/zorza-install.desktop "$home"/Pulpit/zorza-install.desktop
done
# Plymouth i GRUB
plymouth-set-default-theme zorza 2>/dev/null || true
exit 0
