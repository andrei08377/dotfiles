#!/usr/bin/env bash
# install.sh — O COMANDA = TOT sistemul ca acum
# Folosire:  ./install.sh            (instaleaza tot)
#            ./install.sh --dry      (doar arata ce ar face)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0; [ "${1:-}" = "--dry" ] && DRY=1

log()  { printf '\033[1;32m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*"; exit 1; }
run()  { if [ $DRY -eq 1 ]; then echo "  DRY> $*"; else "$@"; fi; }

# =============================================================== detectie ===
ID="$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
LIKE="$(grep '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"' || true)"
PM=""; AUR=""

if   grep -qiE 'arch|cachyos|endeavouros|manjaro' <<<"$ID $LIKE"; then PM="pacman"
elif grep -qiE 'debian|ubuntu|mint|pop' <<<"$ID $LIKE";           then PM="apt"
elif grep -qiE 'fedora|rhel|nobara' <<<"$ID $LIKE";               then PM="dnf"
elif grep -qiE 'opensuse|suse' <<<"$ID $LIKE";                    then PM="zypper"
else die "Distro necunoscut: $ID"; fi

log "Sistem detectat: $ID (package manager: $PM)"

# ============================================================== pachete =====
install_arch() {
    command -v yay >/dev/null || command -v paru >/dev/null || {
        warn "Nu exista AUR helper. Instalez yay..."
        run sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git /tmp/yay-build
        ( cd /tmp/yay-build && run makepkg -si --noconfirm )
    }
    AUR="$(command -v yay || command -v paru)"
    log "Instalez pachetele din repo ($(<"$REPO/lists/packages-arch.txt" wc -l) bucati)..."
    run sudo pacman -S --needed --noconfirm $(grep -vxFf <(pacman -Qqm 2>/dev/null || true) "$REPO/lists/packages-arch.txt" | tr '\n' ' ') || \
        warn "Unele pachete au picat — vezi mai sus. Continui."
    log "Instalez pachete AUR..."
    # shellcheck disable=SC2046
    run $AUR -S --needed $(cat "$REPO/lists/packages-aur.txt" | tr '\n' ' ') || warn "Unele pachete AUR au picat."
}

install_deb() {
    log "Debian/Fedora/SUSE: instalez nucleul comun (best-effort)..."
    local pkgs=(git curl wget python python3-pip python3-venv flatpak bluez bluetooth \
                networkmanager brightnessctl playerctl pamixer grim slurp wl-clipboard \
                swww hyprpaper jq unzip zip)
    case "$PM" in
        apt)    run sudo apt update && run sudo apt install -y ${pkgs[*]} hyprland quickshell || true ;;
        dnf)    run sudo dnf install -y ${pkgs[*]} hyprland || true ;;
        zypper) run sudo zypper install -y ${pkgs[*]} hyprland || true ;;
    esac
    warn "Pe $ID unele pachete Arch/AUR nu exista. Se vor instala alternativele disponibile."
    warn "Pentru paritate completa cu setup-ul original foloseste Arch/CachyOS."
}

case "$PM" in
    pacman) install_arch ;;
    *)      install_deb ;;
esac

# ================================================================ flatpak ===
if [ -s "$REPO/lists/flatpak.txt" ]; then
    log "Flatpak apps..."
    run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    while read -r app; do
        [ -n "$app" ] && run flatpak install -y --noninteractive flathub "$app" || warn "flatpak fail: $app"
    done < "$REPO/lists/flatpak.txt"
fi

# ================================================================ dotfiles ==
log "Restaurez configurile (~/.config)..."
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"

shopt -s nullglob
for d in "$REPO"/dotfiles/config/*/; do
    name="$(basename "$d")"
    if [ -e "$HOME/.config/$name" ] && [ ! -L "$HOME/.config/$name" ]; then
        mv "$HOME/.config/$name" "$HOME/.config/${name}.pre-dotfiles.$(date +%s)"
    fi
    ln -sfn "$d" "$HOME/.config/$name"
done

for f in "$REPO"/dotfiles/config/*.toml "$REPO"/dotfiles/config/*.dirs; do
    [ -f "$f" ] && cp -f "$f" "$HOME/.config/$(basename "$f")"
done
for f in settings.json settings.json.bak; do
    [ -f "$REPO/dotfiles/config/discord/$f" ] && mkdir -p "$HOME/.config/discord" && cp -f "$REPO/dotfiles/config/discord/$f" "$HOME/.config/discord/"
done

log "Restaurez fisiere din HOME..."
for f in "$REPO"/dotfiles/home/.*rc "$REPO"/dotfiles/home/.zprofile "$REPO"/dotfiles/home/.gitconfig; do
    [ -f "$f" ] && cp -f "$f" "$HOME/$(basename "$f")"
done
for d in .themes .icons; do
    [ -d "$REPO/dotfiles/home/$d" ] && rsync -a "$REPO/dotfiles/home/$d/" "$HOME/$d/"
done
[ -d "$REPO/dotfiles/home/oh-my-zsh-custom" ] && [ -d "$HOME/.oh-my-zsh" ] && \
    rsync -a "$REPO/dotfiles/home/oh-my-zsh-custom/" "$HOME/.oh-my-zsh/custom/"

# --- temele Flat-Remix (excluse din repo, ~650MB; se descarca de pe GitHub) ---
if [ ! -d "$HOME/.icons/Flat-Remix-Blue-Dark" ]; then
    log "Descarc iconitele Flat-Remix-Blue-Dark..."
    curl -sL https://github.com/daniruiz/flat-remix/archive/refs/heads/master.tar.gz | \
        tar xz --strip-components=1 -C /tmp flat-remix-master/Flat-Remix-Blue-Dark 2>/dev/null && \
        mkdir -p "$HOME/.icons" && cp -r /tmp/Flat-Remix-Blue-Dark "$HOME/.icons/" && rm -rf /tmp/Flat-Remix-Blue-Dark || \
        warn "Flat-Remix icons: download esuat. Copiaza manual din vechiul PC."
fi
if [ ! -d "$HOME/.themes/Flat-Remix-GTK-Blue-Dark" ]; then
    log "Descarc tema GTK Flat-Remix-GTK-Blue-Dark..."
    curl -sL https://github.com/daniruiz/flat-remix-gtk/archive/refs/heads/master.tar.gz | \
        tar xz --strip-components=2 -C /tmp flat-remix-gtk-master/themes/Flat-Remix-GTK-Blue-Dark 2>/dev/null && \
        mkdir -p "$HOME/.themes" && cp -r /tmp/Flat-Remix-GTK-Blue-Dark "$HOME/.themes/" && rm -rf /tmp/Flat-Remix-GTK-Blue-Dark || \
        warn "Flat-Remix GTK: download esuat. Copiaza manual din vechiul PC."
fi

# ====================================================== scripturi locale ====
log "Instalez scripturile locale (bulbctl, hr-daemon.py...)..."
for f in "$REPO"/dotfiles/local-bin/*; do
    [ -f "$f" ] || continue
    sed "s|/home/[a-z]*|$HOME|g" "$f" > "$HOME/.local/bin/$(basename "$f")"
    chmod +x "$HOME/.local/bin/$(basename "$f")"
done
mkdir -p "$HOME/.local/bin"
cp -f "$REPO"/dotfiles/local-bin/test_hr.py "$REPO"/dotfiles/local-bin/quick_scan.py "$HOME/" 2>/dev/null || true

# bulbctl are shebang catre venv — il repointez DUPA ce construim venvul (mai jos)

# ================================================================= venvs ====
log "Construiesc venv-uri python (puls + bec)..."
python3 -m venv "$HOME/venv-hr"
run "$HOME/venv-hr/bin/pip" install --quiet bleak
mkdir -p "$HOME/.local/share/hama-bulb/venv"
python3 -m venv "$HOME/.local/share/hama-bulb/venv"
run "$HOME/.local/share/hama-bulb/venv/bin/pip" install --quiet tinytuya
sed -i "1s|.*|#!$HOME/.local/share/hama-bulb/venv/bin/python|" "$HOME/.local/bin/bulbctl"
chmod +x "$HOME/.local/bin/bulbctl"

# ================================================================ systemd ===
log "Activez serviciile user (hr-daemon, urserver)..."
mkdir -p "$HOME/.config/systemd/user"
sed "s|/home/[a-z]*|$HOME|g" "$REPO/dotfiles/systemd/user/hr-daemon.service"  > "$HOME/.config/systemd/user/hr-daemon.service"  2>/dev/null || true
sed "s|/home/[a-z]*|$HOME|g" "$REPO/dotfiles/systemd/user/urserver.service"   > "$HOME/.config/systemd/user/urserver.service"   2>/dev/null || true
rsync -a "$REPO/dotfiles/urserver/" "$HOME/.urserver/"
run systemctl --user daemon-reload
run systemctl --user enable --now hr-daemon.service || warn "hr-daemon nu a pornit (bluetooth pornit? senzor aproape?)"
command -v urserver >/dev/null 2>&1 || [ -x /opt/urserver/urserver ] && run systemctl --user enable --now urserver.service

# ============================================================== secrets =====
if [ -f "$REPO/secrets/hama-bulb.json" ]; then
    cp -f "$REPO/secrets/hama-bulb.json" "$HOME/.config/hama-bulb.json"
else
    warn "LIPSA secrets/hama-bulb.json — copiaza-l manual (becul nu va functiona fara el)."
fi

# ============================================================= spicetify ====
log "Setup Spotify + Spicetify..."
if command -v spotify-launcher >/dev/null 2>&1; then
    log "spotify-launcher instalat. Prima rulare descarca clientul Spotify (~100MB)..."
    timeout 120 spotify-launcher --minimized >/dev/null 2>&1 || warn "Spotify client download — ruleaza manual 'spotify-launcher' o data daca lipseste."
fi
if command -v spicetify >/dev/null 2>&1 && [ -d "$(dirname "$(find "$HOME/.local/share/spotify-launcher/install" -maxdepth 4 -name Spotify -type d 2>/dev/null | head -1)" 2>/dev/null)" ]; then
    run spicetify backup apply || run spicetify apply || warn "spicetify apply a esuat — ruleaza manual dupa primul launch Spotify."
    # re-aplica tema salvata din configul restaurat
    run spicetify restore backup apply || true
else
    warn "Spicetify: deschide o data Spotify, apoi ruleaza: spicetify backup apply"
fi

# ================================================================= raport ===
echo
log "========================================================"
log " GATA. Verificari finale:"
log "   - bara:       puls + becul in quickshell (relogin daca lipsesc)"
log "   - teme:       Super+Alt+T (everforest) / Super+Alt+D (dawn)"
log "   - becul:      ~/.local/bin/bulbctl status"
log "   - puls:       systemctl --user status hr-daemon"
log "   - telefon:    Unified Remote app -> PC-ul tau"
log "   - spotify:    spotify-launcher, apoi spicetify backup apply"
log "========================================================"
