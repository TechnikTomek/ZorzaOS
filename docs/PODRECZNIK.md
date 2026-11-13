# Zorza OS 1.0 „Świt”

**Zorza OS** to bootowalna dystrybucja Linuksa oparta na **Debianie 13 „trixie”** i **KDE Plasma 6**.
Ma własną identyfikację wizualną: logo, motywy GRUB, Plymouth, SDDM i Plasmy, 8 proceduralnych tapet oraz
tapetę dynamiczną dzień/noc. Dołączone są też własne aplikacje *Witaj* i *System Center*.

Z jednego projektu i jednego skryptu powstają dwa obrazy:

| Plik | Dla kogo | Rozruch |
|---|---|---|
| `zorza-1.0-amd64.iso` | PC z Intel/AMD, VirtualBox na Windows/Linux | UEFI **i** legacy BIOS (ISO hybrydowe: płyta + pendrive) |
| `zorza-1.0-arm64.iso` | Mac z Apple Silicon (M1–M4) w VirtualBox 7.1+, inne maszyny ARM64 z UEFI | UEFI |

> Nazwa nawiązuje do zorzy, czyli łuny światła nad linią horyzontu. Inne rozważane nazwy to Azymut, Brzask,
> Lunara i Vesper. Wybrałem „Zorzę”, bo jedno krótkie polskie słowo opisuje świecący horyzont i od razu
> podsuwa paletę oraz motyw dzień/noc.

---

## Spis treści
1. [Co jest w środku](#co-jest-w-środku)
2. [Budowanie ISO](#budowanie-iso) (Docker na Linux/macOS/WSL2, GitHub Actions)
3. [Nagrywanie na pendrive](#nagrywanie-na-pendrive)
4. [VirtualBox na Windows (x86_64)](#virtualbox-na-windows-x86_64)
5. [VirtualBox na Macu z Apple Silicon](#virtualbox-na-macu-z-apple-silicon-m1m4)
6. [Pierwsze uruchomienie i instalacja](#pierwsze-uruchomienie-i-instalacja)
7. [Znane ograniczenia](#znane-ograniczenia)
8. [Struktura projektu](#struktura-projektu)

---

## Co jest w środku

| Obszar | Zawartość |
|---|---|
| Baza | Debian 13 trixie (main, contrib, non-free-firmware), jądro 6.12 LTS, `live-build` |
| Pulpit | KDE Plasma 6.3 (Wayland, X11 jako sesja zapasowa), SDDM z własnym motywem |
| Wygląd | globalne motywy **Zorza Ciemny / Zorza Jasny**, pływający dock + minimalistyczny górny pasek, rozmycie paneli, 6 kolorów akcentu |
| Ikony i fonty | Papirus z folderami w kolorze akcentu (motywy `Zorza-Dark/Light[-akcent]`), kursory Breeze, **Inter** (UI), **JetBrains Mono** (terminal) |
| Tapety | Zorza, Świt, Fale, Kryształ, Głębia, Zmierzch, Wydmy, Mgła, a do tego **Horyzont**: tapeta dynamiczna w 4 porach dnia (świt, dzień, zmierzch, noc). Wszystkie 3840×2160, generowane skryptem |
| Rozruch | motyw GRUB (menu PL/EN, tryb bezpieczny grafiki, ładowanie do RAM), animowany Plymouth, KSplash |
| Aplikacje | Firefox ESR, Dolphin, Konsole (profil „Zorza”), Kate, LibreOffice (integracja z KDE), VLC, Gwenview, Elisa, Okular, GIMP, Inkscape, Spectacle, Ark, Monitor systemu, KCalc, Discover z **Flathubem** |
| Własne | **Witaj**: motyw, akcent, tapeta, efekty, „Zainstaluj na dysku”. **System Center**: sprzęt, wygląd, tapety, aktualizacje APT + Flatpak jednym kliknięciem. `zorza-appearance`: to samo z terminala |
| Instalator | Calamares z brandingiem Zorzy (slajdy PL/EN), UEFI + BIOS, opcjonalne szyfrowanie LUKS |
| Wirtualizacja | VirtualBox Guest Utils (amd64, z Debian fasttrack), sterowniki VMSVGA/vmwgfx, virtio, SPICE, QEMU guest agent |
| Ustawienia regionalne | język polski, klawiatura PL, strefa Europe/Warsaw. W menu GRUB można wybrać English/US |
| Sesja live | użytkownik `live`, hasło `live`, automatyczne logowanie |

### Efekty ON/OFF
Przy pierwszym logowaniu Zorza sprawdza, czy KWin ma akcelerację 3D. Jeśli renderuje programowo
(np. VirtualBox bez 3D albo llvmpipe), wyłącza rozmycie i animacje. Przełącznik jest w trzech miejscach:
- „Efekty wł./wył.” w menu aplikacji (ulubione),
- aplikacje *Witaj* i *System Center*,
- polecenie `zorza-appearance effects on|off|toggle|auto`.

---

## Budowanie ISO

### Wymagania
- **Docker** (Docker Desktop na Windows/macOS, Docker Engine na Linuksie; na Macu działa też OrbStack/Colima).
- ok. **40 GB** wolnego miejsca i 8 GB RAM; połączenie z internetem (pobierane jest ok. 2,5 GB pakietów).
- Kontener działa w trybie `--privileged` (live-build montuje systemy plików i tworzy chroot).

### Jedno polecenie
```bash
./build.command amd64
```
```bash
./build.command arm64
```
```bash
./build.command all
```
Wynik trafia do katalogu `out/`:
```
out/zorza-1.0-amd64.iso
out/zorza-1.0-amd64.iso.sha256
out/zorza-1.0-amd64.packages   # lista pakietów w obrazie
out/SHA256SUMS
```

Opcje:

| Opcja / zmienna | Znaczenie |
|---|---|
| `--clean` | buduje od zera (bez cache) |
| `--native` | bez Dockera: na hoście Debian 13 z zainstalowanym `live-build`, jako root |
| `ZORZA_SQUASHFS=zstd` | szybsza kompresja przy testach (ISO większe o ok. 15%). Domyślnie `xz` |
| `ZORZA_MIRROR=https://ftp.pl.debian.org/debian` | inny mirror Debiana |
| `ZORZA_EXTRA_CA=/ścieżka/ca.crt` | dodatkowy certyfikat CA (sieć firmowa z proxy, które podmienia certyfikaty TLS) |
| `https_proxy=…` | proxy HTTP(S). Kontener dostaje je automatycznie, buduje z `--network host`, a konfiguracja proxy nie trafia do ISO |

Czas budowania: 30–60 min dla amd64 na typowym PC. Budowanie **arm64 na komputerze x86** działa przez emulację
`qemu-user-static` + `binfmt_misc` i trwa 2–4 razy dłużej. Na Macu z Apple Silicon jest odwrotnie: arm64 buduje się
natywnie, a amd64 przez emulację. Kolejne buildy korzystają z cache pakietów w wolumenie Dockera
`zorza-work-<arch>`.

**Windows (WSL2):** zainstaluj Docker Desktop z backendem WSL2, otwórz terminal Ubuntu w WSL i sklonuj repozytorium
**do systemu plików Linuksa** (np. `~/zorza-os`, nie `/mnt/c/...`), a potem uruchom `./build.command amd64`.

**macOS:** zainstaluj i uruchom Docker Desktop (Settings → Resources: daj mu min. 8 GB RAM i 60 GB dysku).
Potem kliknij dwukrotnie `build.command` w Finderze. Pojawi się menu z wyborem architektury (Enter = arm64 na
Macu z Apple Silicon). Możesz też uruchomić `./build.command arm64` w Terminalu. Jeśli macOS zablokuje plik jako
pobrany z internetu, kliknij go prawym przyciskiem → Otwórz albo wykonaj `xattr -dr com.apple.quarantine .` w katalogu projektu.

### GitHub Actions
Workflow `.github/workflows/build-iso.yml` buduje oba obrazy **równolegle na natywnych runnerach**:
- `ubuntu-latest` → amd64,
- `ubuntu-24.04-arm` → arm64.

| Zdarzenie | Wynik |
|---|---|
| push, PR, ręczne uruchomienie (*Actions → Build ISO → Run workflow*) | ISO jako **artefakty** (14 dni) |
| tag `v*`, np. `git tag v1.0 && git push --tags` | do tego **szkic Release** z ISO i `SHA256SUMS` |

GitHub przyjmuje w Release pliki do 2 GB, więc większe ISO są dzielone na części `*.iso.part0`, `*.part1`. Łączenie:
```bash
cat zorza-1.0-amd64.iso.part* > zorza-1.0-amd64.iso && sha256sum -c SHA256SUMS --ignore-missing
```
```bat
copy /b zorza-1.0-amd64.iso.part0+zorza-1.0-amd64.iso.part1 zorza-1.0-amd64.iso
```

---

## Nagrywanie na pendrive

Pendrive min. **8 GB**. **Cała zawartość zostanie usunięta.**

### Windows
- **balenaEtcher**: *Flash from file* → wybierz ISO → *Select target* → pendrive → *Flash!*
- **Rufus**: wybierz pendrive i ISO. Schemat partycji: **GPT** (komputery z UEFI) lub **MBR** (stare BIOS).
  Gdy Rufus zapyta o tryb zapisu obrazu ISOHybrid, wybierz **„Zapisz w trybie obrazu DD”**. To najpewniejsza metoda.

### macOS
- **balenaEtcher**: tak samo jak na Windows.
- **dd** w Terminalu:
  ```bash
  diskutil list                          # znajdź pendrive, np. /dev/disk4
  ```
  ```bash
  diskutil unmountDisk /dev/disk4
  ```
  ```bash
  sudo dd if=zorza-1.0-amd64.iso of=/dev/rdisk4 bs=4m status=progress
  ```
  ```bash
  diskutil eject /dev/disk4
  ```

### Linux
```bash
sudo dd if=zorza-1.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

**Start z pendrive'a:** przy włączaniu komputera naciśnij klawisz menu rozruchu (zwykle F12, F11, F8, Esc lub F2).
Zorza 1.0 nie ma podpisu Secure Boot dla własnych modułów. Jeśli rozruch zostanie zablokowany, wyłącz Secure Boot
w ustawieniach UEFI.

> **Mac z Apple Silicon nie uruchomi żadnego ISO z pendrive'a** (to ograniczenie sprzętowe Apple).
> Na Macu używaj obrazu `arm64` w VirtualBox.

---

## VirtualBox na Windows (x86_64)

VirtualBox **7.0 lub nowszy** (zalecany 7.1/7.2). *Maszyna → Nowa*:

| Ustawienie | Wartość |
|---|---|
| Nazwa | Zorza OS |
| Obraz ISO | `zorza-1.0-amd64.iso` |
| Typ / Wersja | **Linux / Debian (64-bit)** |
| Instalacja nienadzorowana | **odznacz** (*Skip Unattended Installation*) |
| Pamięć RAM | **4096 MB** (minimum), zalecane 8192 MB |
| Procesory | **2–4** |
| EFI | **Włącz** (*Enable EFI*). Wersja amd64 uruchomi się też bez EFI, w trybie BIOS |
| Dysk | **25 GB** VDI, dynamicznie przydzielany |
| Ekran → Kontroler grafiki | **VMSVGA** |
| Ekran → Pamięć wideo | **128 MB** |
| Ekran → Akceleracja 3D | wyłączona (stabilniej). Po włączeniu Zorza sama włączy efekty |
| Sieć | NAT |
| USB | kontroler USB 3.0 (xHCI) |
| Ogólne → Zaawansowane | Współdzielony schowek: **Dwukierunkowy** |

Uruchom maszynę i wybierz w menu **„Zorza OS — Live (Polski)”**. Rozdzielczość dopasowuje się do rozmiaru okna
automatycznie, przez VMSVGA/vmwgfx. Narzędzia gościa (schowek, foldery współdzielone) są już w obrazie, więc nie
trzeba wkładać płyty *Guest Additions*.

Jeśli ekran zostaje czarny, w menu wybierz *Opcje zaawansowane → Tryb bezpieczny grafiki*.

## VirtualBox na Macu z Apple Silicon (M1–M4)

Wymagany **VirtualBox 7.1 lub nowszy** dla macOS / Apple Silicon (pakiet *macOS / Apple Silicon hosts*).

| Ustawienie | Wartość |
|---|---|
| Obraz ISO | `zorza-1.0-arm64.iso` |
| Typ / Podtyp / Wersja | **Linux / Debian / Debian (ARM 64-bit)** |
| Instalacja nienadzorowana | **odznacz** |
| Pamięć RAM | **4096 MB** (minimum), zalecane 8192 MB |
| Procesory | **2–4** (rdzenie wydajnościowe) |
| EFI | **włączone** (na ARM jest obowiązkowe i domyślne) |
| Dysk | **25 GB** VDI (kontroler VirtIO SCSI lub domyślny NVMe) |
| Ekran → Kontroler grafiki | **VMSVGA** |
| Ekran → Pamięć wideo | **128 MB** |
| Akceleracja 3D | wyłączona |
| Sieć | NAT |
| USB | USB 3.0 (xHCI) z tabletem USB (płynna mysz) |

> **Błąd `Unsupported CPU (VERR_UNSUPPORTED_CPU)` przy starcie maszyny** oznacza, że maszyna została utworzona
> jako **x86** (np. *Debian (64-bit)* albo z obrazem `amd64`). VirtualBox na Apple Silicon uruchamia wyłącznie
> systemy ARM. Usuń tę maszynę i utwórz nową: **Version → Debian (ARM 64-bit)** i obraz `zorza-1.0-arm64.iso`
> (architektury istniejącej maszyny nie da się zmienić). Używaj najnowszego VirtualBox 7.2.x.

> Ten sam błąd przy maszynie **ARM** oznacza, że VirtualBox nie obsługuje procesora tego Maca (dotyczy najnowszych
> układów, np. A18 Pro w MacBooku Neo). Wtedy użyj UTM, opisanego niżej.

### UTM (alternatywa dla VirtualBox na każdym Macu z Apple Silicon)
UTM jest darmowy: https://mac.getutm.app (lub App Store).
1. **Create a New Virtual Machine → Virtualize → Linux.**
2. *Boot ISO Image*: `zorza-1.0-arm64.iso`. Opcję *Use Apple Virtualization* zostaw **wyłączoną** (backend QEMU jest
   bardziej zgodny z obrazami live).
3. Pamięć **4096 MB** lub więcej, rdzenie **4**.
4. Dysk **25 GB**, katalog współdzielony możesz pominąć.
5. Zapisz, a potem w ustawieniach maszyny: *Display → virtio-gpu-gl-pci* (lub *virtio-ramfb*, jeśli obraz miga).
6. Uruchom i wybierz w menu „Zorza OS — Live (Polski)”. Po instalacji na dysk usuń ISO z napędu CD (*CD/DVD → Clear*).

Po starcie wybierz język w menu GRUB. Efekty zostaną wyłączone automatycznie (brak 3D), a pulpit pozostaje płynny.

---

## Pierwsze uruchomienie i instalacja

1. W menu GRUB wybierz **Polski** albo **English**. Ustawia to język systemu i układ klawiatury.
2. System loguje się sam (`live` / `live`). Pojawia się aplikacja **Witaj**: motyw jasny/ciemny, akcent, tapeta,
   efekty i przycisk **„Zainstaluj na dysku”**.
3. Instalator **Calamares** jest też pod ikoną *Zainstaluj Zorza OS* na pulpicie. Przeprowadzi Cię przez wybór
   języka, strefy czasowej, klawiatury, partycjonowanie (z opcją szyfrowania), użytkownika i podsumowanie.
   Instalacja trwa zwykle 5–15 minut.
4. Po restarcie (wyjmij ISO lub pendrive) zobaczysz ekran logowania Zorzy. Aktualizacje zrobisz w
   **System Center → Aktualizacje → Zaktualizuj wszystko**.

Przydatne polecenia:
```bash
zorza-appearance status
```
```bash
zorza-appearance theme light
```
```bash
zorza-appearance accent teal
```
```bash
zorza-appearance wallpaper dynamic
```
```bash
fastfetch
```

---

## Znane ograniczenia

| Obszar | Ograniczenie |
|---|---|
| arm64 + VirtualBox | Pakietu **Guest Additions dla arm64 nie ma w obrazie**, więc nie działa schowek współdzielony, przeciąganie plików ani foldery współdzielone. Rozdzielczość nadal dopasowuje się do okna (Wayland + vmwgfx). Pliki przenosisz przez sieć lub pendrive USB |
| Wydajność bez 3D | VirtualBox nie ma akceleracji 3D dla gości na Apple Silicon, a na x86 jest ona opcjonalna. Bez niej KWin renderuje programowo, więc Zorza wyłącza rozmycie i animacje. Odtwarzanie wideo 4K i gry 3D będą wolne |
| Apple Silicon na sprzęcie | ISO arm64 **nie uruchomi się bezpośrednio na Macu** (tylko w maszynie wirtualnej) |
| Secure Boot | jądro i GRUB są podpisane przez Debiana, ale moduły dodatków VirtualBox nie są. Przy problemach wyłącz Secure Boot |
| Rozmiar ISO | ok. 3–3,5 GB (pełny LibreOffice, GIMP, Inkscape i firmware) |
| Pakiety firmware | w obrazie są popularne sterowniki (Intel, AMD, Realtek, Atheros, Broadcom, MediaTek). Rzadkie układy mogą wymagać doinstalowania firmware z repozytorium Debiana |
| Tapeta dynamiczna | pory dnia są przybliżone dla Europy Środkowej (lato/zima), bez obliczania położenia słońca |
| Testy | wersję amd64 przetestowano w QEMU (UEFI). ISO arm64 buduje się z tej samej konfiguracji, ale na urządzeniach Apple Silicon sprawdza się je ręcznie |

---

## Struktura projektu

```
zorza-os/
├── build.command                 # ./build.command amd64|arm64|all
├── zorza.conf                    # nazwa, wersja, kod wydania
├── Dockerfile                    # środowisko budowania (Debian 13 + live-build)
├── docker/certs/                 # opcjonalne dodatkowe CA (np. proxy firmowe)
├── .github/workflows/build-iso.yml
├── scripts/
│   ├── container-build.sh        # budowanie jednej architektury (bootstrap → chroot → binary)
│   ├── lb-config.sh              # parametry `lb config` dla amd64 / arm64
│   ├── render-assets.py          # tapety 4K, logo PNG, tło GRUB/Plymouth/SDDM, slajdy Calamares
│   └── test-qemu.sh              # test: rozruch w QEMU + zrzut ekranu
├── branding/
│   ├── palette.json              # paleta kolorów (jedno źródło)
│   ├── logo/*.svg                # znak, wordmark, ikona symboliczna
│   └── ascii/zorza.txt           # logo dla fastfetch
└── config/                       # drzewo live-build
    ├── package-lists/*.list.chroot
    ├── hooks/normal/*.hook.chroot
    ├── bootloaders/grub-pc/      # menu GRUB PL/EN + motyw
    └── includes.chroot/          # pliki systemu: motywy, aplikacje Zorza, Calamares, konfiguracja
```

### Paleta

| Nazwa | Kolor | Użycie |
|---|---|---|
| Noc | `#0E1530` | tła ciemne |
| Głębia | `#1B2350` | panele, karty |
| Fiolet zorzy | `#7C5CFF` | akcent domyślny |
| Róż świtu | `#FF6FA3` | akcent, gradienty |
| Złoto | `#FFB547` | słońce, ostrzeżenia |
| Turkus | `#2FD4C4` | zorza, akcent |
| Mgła | `#F4F5FB` | tła jasne |

### Licencje
Kod projektu: GPL-3.0-or-later (plik `LICENSE`). Grafiki (logo, tapety, motywy) zostały wygenerowane na potrzeby projektu (`LICENSE-ARTWORK.md`):
CC BY-SA 4.0. Pakiety Debiana zachowują własne licencje.
