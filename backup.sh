#!/usr/bin/env bash
# backup.sh — captureaza starea COMPLETA a sistemului in repo
# Ruleaza ORICAND pe sistemul functional: ./backup.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$REPO/dotfiles/config"
HOME_DIR="$HOME"

log() { printf '\033[1;36m[backup]\033[0m %s\n' "$*"; }

mkdir -p "$CFG" "$REPO/dotfiles/home" "$REPO/dotfiles/local-bin" \
         "$REPO/dotfiles/systemd/user" "$REPO/dotfiles/urserver" \
         "$REPO/lists" "$REPO/venvs" "$REPO/secrets"

# ---------------------------------------------------------------- pachete ---
log "Liste pachete..."
pacman -Qqe > "$REPO/lists/packages-arch.txt"
pacman -Qqm > "$REPO/lists/packages-aur.txt" 2>/dev/null || true
flatpak list --app --columns=application > "$REPO/lists/flatpak.txt" 2>/dev/null || true

# ----------------------------------------------------------------- configs --
# Directoare luate INTREGI (config real, fara cache)
FULL_DIRS=(
    hypr quickshell spicetify wallust waybar rofi fuzzel ghostty alacritty
    kitty foot swaync wlogout uwsm cava btop fastfetch micro gtk-3.0 gtk-4.0
    xsettingsd systemd zsh fish
)
for d in "${FULL_DIRS[@]}"; do
    [ -d "$HOME_DIR/.config/$d" ] && rsync -a --delete "$HOME_DIR/.config/$d/" "$CFG/$d/"
done

# Fisiere mici din .config
for f in starship.toml user-dirs.dirs qml_color.json; do
    [ -f "$HOME_DIR/.config/$f" ] && cp -f "$HOME_DIR/.config/$f" "$CFG/"
done

# starship.toml + hama-bulb.json in locurile lor logice
[ -f "$HOME_DIR/.config/starship.toml" ] && cp -f "$HOME_DIR/.config/starship.toml" "$CFG/"
[ -f "$HOME_DIR/.config/hama-bulb.json" ] && cp -f "$HOME_DIR/.config/hama-bulb.json" "$REPO/secrets/hama-bulb.json"

# Discord: doar setari (nu cache de 700MB)
mkdir -p "$CFG/discord"
for f in settings.json settings.json.bak; do
    [ -f "$HOME_DIR/.config/discord/$f" ] && cp -f "$HOME_DIR/.config/discord/$f" "$CFG/discord/"
done
# Vencord complet (teme, plugins)
[ -d "$HOME_DIR/.config/Vencord" ] && rsync -a --delete "$HOME_DIR/.config/Vencord/" "$CFG/Vencord/"

# ------------------------------------------------------------------ home ----
for f in .zshrc .zprofile .bashrc .gitconfig .tmux.conf; do
    [ -f "$HOME_DIR/$f" ] && cp -f "$HOME_DIR/$f" "$REPO/dotfiles/home/"
done
# oh-my-zsh custom (teme/plugins instalate manual)
if [ -d "$HOME_DIR/.oh-my-zsh/custom" ]; then
    mkdir -p "$REPO/dotfiles/home/oh-my-zsh-custom"
    rsync -a --delete --exclude=.git "$HOME_DIR/.oh-my-zsh/custom/" "$REPO/dotfiles/home/oh-my-zsh-custom/"
fi

# teme GTK/iconite personalizate local
# (Flat-Remix e EXCLUS din repo — ~650MB; il instaleaza install.sh de pe GitHub)
for d in .themes .icons; do
    [ -d "$HOME_DIR/$d" ] && rsync -a --delete \
        --exclude='Flat-Remix*' \
        "$HOME_DIR/$d/" "$REPO/dotfiles/home/${d}/"
done

# ------------------------------------------------------- scripturi locale ---
for f in bulbctl hr-daemon.py; do
    [ -f "$HOME_DIR/.local/bin/$f" ] && cp -f "$HOME_DIR/.local/bin/$f" "$REPO/dotfiles/local-bin/"
done
for f in test_hr.py quick_scan.py; do
    [ -f "$HOME_DIR/$f" ] && cp -f "$HOME_DIR/$f" "$REPO/dotfiles/local-bin/"
done

# -------------------------------------------------------- systemd units -----
cp -f "$HOME_DIR/.config/systemd/user/hr-daemon.service" "$REPO/dotfiles/systemd/user/" 2>/dev/null || true
cp -f "$HOME_DIR/.config/systemd/user/urserver.service"  "$REPO/dotfiles/systemd/user/" 2>/dev/null || true

# ---------------------------------------------------------- urserver --------
for f in urserver.config remotes; do
    if [ -e "$HOME_DIR/.urserver/$f" ]; then
        rsync -a --delete "$HOME_DIR/.urserver/$f" "$REPO/dotfiles/urserver/"
    fi
done

# --------------------------------------------------------------- venvs ------
log "Export dependinte python (pip freeze)..."
if [ -x "$HOME_DIR/venv-hr/bin/pip" ]; then
    "$HOME_DIR/venv-hr/bin/pip" freeze --all > "$REPO/venvs/requirements-hr.txt"
fi
BULB_PY="$(find "$HOME_DIR/.local/share/hama-bulb/venv/bin" -name 'python*' -type f 2>/dev/null | head -1)"
if [ -n "$BULB_PY" ]; then
    "$BULB_PY" -m pip freeze --all > "$REPO/venvs/requirements-bulb.txt"
fi

# -------------------------------------------------------------- secrets -----
# hama-bulb.json e GITIGNORE-uit; exemplu pentru structura:
cat > "$REPO/secrets/hama-bulb.json.example" <<'EOF'
{ "id": "...", "ip": "192.168.1.x", "key": "...", "version": 3.3 }
EOF

log "GATA. Capturat in: $REPO"
log "Urmatorul pas: git add -A && git commit si push pe GitHub (repo privat!)"
