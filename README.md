# dotfiles — setup complet Andrei

O comandă = tot sistemul: bara cu puls live, widget becul, teme (Super+Alt+T/D),
Spotify+Spicetify, control PC din telefon, toate scripturile și fixurile.

## Pe sistemul ACTUAL (când schimbi ceva)

```bash
cd ~/Projects/dotfiles
./backup.sh
git add -A && git commit -m "update" && git push
```

## Pe PC NOU

```bash
git clone <URL-repo-privat> ~/Projects/dotfiles
cd ~/Projects/dotfiles
./install.sh          # --dry ca sa vezi doar planul
```

Apoi: **log out / log in** și deschide o dată Spotify (`spotify-launcher`),
apoi `spicetify backup apply`.

## Ce restaurează install.sh

- Pachetele exacte (328 repo + 21 AUR pe Arch/CachyOS) + Flatpak apps
- ~/.config complet: Hyprland (KooL), quickshell/caelestia cu widget-urile
  **HeartRate** și **Bulb**, spicetify, wallust, waybar, rofi, etc.
- Scripturi: `bulbctl`, `hr-daemon.py`, `test_hr.py`, `quick_scan.py`
- Servicii systemd user: `hr-daemon` (puls BLE → bară), `urserver` (telefon)
- Temele: Bibata cursor, Flat-Remix Blue Dark (descărcat de pe GitHub)
- venv-uri python reconstruite automat (bleak + tinytuya)
- Spotify + spicetify cu schemele EverforestDarkHard / RosePineDawn

## SECRETE (nu urca niciodată pe repo public!)

- `secrets/hama-bulb.json` — cheia becului (gitignored)
- MAC-ul senzorului puls e în `dotfiles/local-bin/hr-daemon.py`

## Suport multi-distro

Arh/CachyOS = paritate 100%. Debian/Fedora/openSUSE = nucleu comun best-effort
(Hyprland, flatpak, bluetooth...) + raport despre ce lipsește.

## Cerințe hardware

- Virtualizare (KVM) activă în BIOS dacă vrei VM de test
- Bluetooth ON pentru hr-daemon; becul trebuie pe aceeași rețea
