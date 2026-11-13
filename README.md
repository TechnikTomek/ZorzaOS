<div align="center">

<img src="docs/banner.png" alt="Zorza OS – Debian 13, KDE Plasma 6, amd64 + arm64" width="100%">

### Polski Linux na co dzień. Piękny od menu startowego po ekran logowania.

[![Gwiazdki](https://img.shields.io/github/stars/zorza-os/zorza-os?style=for-the-badge&logo=github&label=Gwiazdki&color=7C5CFF)](https://github.com/zorza-os/zorza-os/stargazers)
[![Build ISO](https://img.shields.io/github/actions/workflow/status/zorza-os/zorza-os/build-iso.yml?style=for-the-badge&logo=githubactions&logoColor=white&label=Build%20ISO)](https://github.com/zorza-os/zorza-os/actions/workflows/build-iso.yml)
[![Wydanie](https://img.shields.io/github/v/release/zorza-os/zorza-os?include_prereleases&style=for-the-badge&label=Wydanie&color=FF6FA3)](https://github.com/zorza-os/zorza-os/releases)
[![Pobrania](https://img.shields.io/github/downloads/zorza-os/zorza-os/total?style=for-the-badge&label=Pobrania&color=2FD4C4)](https://github.com/zorza-os/zorza-os/releases)
[![Licencja](https://img.shields.io/badge/Licencja-GPL--3.0-FFB547?style=for-the-badge)](LICENSE)

![Debian 13](https://img.shields.io/badge/Debian-13%20trixie-A81D33?style=flat-square&logo=debian&logoColor=white)
![KDE Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6.3-1D99F3?style=flat-square&logo=kde&logoColor=white)
![amd64](https://img.shields.io/badge/amd64-UEFI%20%2B%20BIOS-4C8DFF?style=flat-square&logo=intel&logoColor=white)
![arm64](https://img.shields.io/badge/arm64-Apple%20Silicon-555?style=flat-square&logo=apple&logoColor=white)
![Język](https://img.shields.io/badge/j%C4%99zyk-polski%20%2B%20English-DC143C?style=flat-square)
![Wayland](https://img.shields.io/badge/Wayland-gotowe-3DDC84?style=flat-square&logo=wayland&logoColor=white)

[**Pobierz**](https://github.com/zorza-os/zorza-os/releases) ·
[**Strona projektu**](https://zorza-os.github.io/zorza-os/) ·
[**Podręcznik**](docs/PODRECZNIK.md) ·
[**Zgłoś błąd**](https://github.com/zorza-os/zorza-os/issues)

</div>

---

<p align="center">
  <img src="website/img/desktop.jpg" alt="Pulpit Zorza OS: zorza polarna nad jeziorem, górny pasek i pływający dock" width="88%">
</p>

## ✨ Co to jest

**Zorza OS** to dystrybucja Linuksa zbudowana na **Debianie 13 „trixie”** i **KDE Plasma 6**. Ma własną oprawę
wizualną na każdym etapie: menu GRUB, ekran ładowania, logowanie, pulpit i instalator. Działa jako Live CD/USB
z opcją instalacji na dysk i powstaje z jednego skryptu dla dwóch architektur.

## 🖥️ Obsługiwane platformy

| Platforma | Obraz | Rozruch | Status |
|---|---|---|---|
| PC z procesorem Intel / AMD | `zorza-1.0-amd64.iso` | UEFI + legacy BIOS | ✅ przetestowany (QEMU, UEFI) |
| VirtualBox na Windows / Linux | `zorza-1.0-amd64.iso` | UEFI lub BIOS | ✅ zalecany VMSVGA, dodatki gościa w zestawie |
| Mac z Apple Silicon w **UTM** | `zorza-1.0-arm64.iso` | UEFI | 🧪 beta |
| Mac z Apple Silicon w VirtualBox 7.1+ | `zorza-1.0-arm64.iso` | UEFI | ⚠️ zależy od procesora (najnowsze układy nieobsługiwane przez VirtualBox) |
| Pendrive USB (Rufus, balenaEtcher, `dd`) | `amd64` | UEFI + BIOS | ✅ obraz hybrydowy |

## 🎨 Najważniejsze cechy

<table>
<tr>
<td width="50%" valign="top">

**Wygląd**
- motywy **Zorza Ciemny** i **Zorza Jasny**
- **6 kolorów akcentu**, także dla ikon folderów (Papirus)
- pływający dock i minimalistyczny górny pasek
- rozmycie paneli; efekty wyłączają się same bez 3D
- fonty **Inter** i **JetBrains Mono**
- **9 tapet 4K** narysowanych kodem, w tym dynamiczna **Horyzont** (świt, dzień, zmierzch, noc)

</td>
<td width="50%" valign="top">

**Wygoda**
- polski od pierwszego uruchomienia, w GRUB do wyboru **Polski / English**
- aplikacja **Witaj**: motyw, akcent, tapeta i instalacja na dysk
- **System Center**: sprzęt, wygląd i aktualizacje APT + Flatpak jednym kliknięciem
- **Discover** z Flathubem
- instalator **Calamares** z szyfrowaniem dysku
- sesja live: `live` / `live`, automatyczne logowanie

</td>
</tr>
</table>

## 📸 Zrzuty ekranu

| Menu startowe | Ekran ładowania |
|---|---|
| ![Menu GRUB z wyborem języka](website/img/grub.jpg) | ![Ekran ładowania Plymouth](website/img/plymouth.jpg) |
| **Witaj** | **System Center** |
| ![Aplikacja Witaj: motyw i akcent](website/img/app-welcome.jpg) | ![System Center: informacje o sprzęcie](website/img/app-center.jpg) |

<details>
<summary><b>Tapety (kliknij, aby rozwinąć)</b></summary>

| | | |
|---|---|---|
| ![Zorza](website/img/Zorza.jpg) Zorza | ![Świt](website/img/Swit.jpg) Świt | ![Fale](website/img/Fale.jpg) Fale |
| ![Kryształ](website/img/Krysztal.jpg) Kryształ | ![Głębia](website/img/Glebia.jpg) Głębia | ![Zmierzch](website/img/Zmierzch.jpg) Zmierzch |
| ![Wydmy](website/img/Wydmy.jpg) Wydmy | ![Mgła](website/img/Mgla.jpg) Mgła | ![Horyzont](website/img/phase-noc.jpg) Horyzont (dynamiczna) |

</details>

## 📦 Aplikacje w zestawie

| Kategoria | Aplikacje |
|---|---|
| Internet | Firefox ESR |
| Biuro | LibreOffice, Okular, Kate |
| Grafika | GIMP, Inkscape, Gwenview, Spectacle |
| Multimedia | VLC, Elisa |
| System | Dolphin, Konsole, Ark, KCalc, Monitor systemu |
| Sklep | Discover + Flathub |

## 🚀 Szybki start

**Pobierz** gotowy obraz z zakładki [Releases](https://github.com/TechnikTOmek/zorza-os/releases) albo **zbuduj go sam**.
Potrzebujesz tylko Dockera (Linux, macOS, WSL2 na Windows):

```bash
git clone https://github.com/zorza-os/zorza-os.git
```
```bash
cd zorza-os
```
```bash
./build.command amd64
```

Na Macu wystarczy dwuklik na `build.command`. Pojawi się menu wyboru architektury. Gotowe ISO trafi do `out/`
razem z sumami SHA256.

Szczegóły (pendrive, ustawienia VirtualBox i UTM, znane ograniczenia) są w **[podręczniku](docs/PODRECZNIK.md)**.

## 🛠️ Jak to jest zbudowane

```
build.command ──► Docker (Debian 13 + live-build)
                    ├─ scripts/render-assets.py   tapety 4K, logo, motywy GRUB / Plymouth / SDDM
                    ├─ config/package-lists        pakiety (wspólne + osobne dla amd64 / arm64)
                    ├─ config/hooks                konfiguracja systemu w chroocie
                    └─ config/includes.chroot      motywy Plasmy, aplikacje Zorza, Calamares
                  ──► out/zorza-1.0-<arch>.iso
```

GitHub Actions buduje **oba obrazy równolegle** na natywnych runnerach (`ubuntu-latest` dla amd64 i
`ubuntu-24.04-arm` dla arm64). Tag `v*` tworzy szkic wydania z plikami ISO.

## 🤝 Współpraca

Zgłoszenia błędów, pomysły i pull requesty są mile widziane. Jeśli Zorza Ci się podoba,
**zostaw ⭐**. To najprostszy sposób, żeby pomóc projektowi.

[![Historia gwiazdek](https://api.star-history.com/svg?repos=zorza-os/zorza-os&type=Date)](https://star-history.com/#zorza-os/zorza-os&Date)

## 📄 Licencja

- Kod (skrypty, konfiguracja, aplikacje): **[GPL-3.0-or-later](LICENSE)**
- Grafiki (logo, tapety, motywy): **[CC BY-SA 4.0](LICENSE-ARTWORK.md)**
- Pakiety Debiana w obrazach ISO zachowują własne licencje.

<div align="center"><sub>Zorza OS nie jest powiązany z projektem Debian ani KDE e.V. Nazwy Debian i KDE należą do ich właścicieli.</sub></div>
