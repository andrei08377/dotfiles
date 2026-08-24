#!/usr/bin/env bash
## Switch Caelestia scheme + Spicetify theme together
## Usage: CaelestiaTheme.sh <everforest|dawn>

set -u

theme="${1:-}"
scriptsDir="$HOME/.config/hypr/scripts"
log="/tmp/caelestia-theme.log"

notify() {
    notify-send -u normal -a "CaelestiaTheme" "Theme" "$1"
}

case "$theme" in
everforest)
    scheme=(-n everforest -f hard -m dark)
    sp_scheme="EverforestDarkHard"
    label="Everforest (hard, dark)"
    ;;
dawn|rosepinedawn)
    scheme=(-n rosepine -f dawn -m light)
    sp_scheme="RosePineDawn"
    label="Rose Pine Dawn"
    ;;
*)
    echo "Usage: $0 <everforest|dawn>" >&2
    exit 1
    ;;
esac

{
    if caelestia scheme set "${scheme[@]}" >>"$log" 2>&1; then
        notify "$label applied to Caelestia"
    else
        notify "caelestia scheme set failed (see $log)"
        exit 1
    fi

    if spicetify config current_theme text color_scheme "$sp_scheme" replace_colors 1 && spicetify apply >>"$log" 2>&1; then
        notify "$label applied to Spotify"
    else
        notify "spicetify apply failed (see $log)"
    fi
} &
