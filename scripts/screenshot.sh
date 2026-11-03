#!/usr/bin/env bash
# Select a region, then annotate, copy, or save it in Satty.
set -euo pipefail

geometry=$(/usr/bin/slurp -d) || exit 0
[[ -n "$geometry" ]] || exit 0

pictures_dir=$(/usr/bin/xdg-user-dir PICTURES)
if [[ -z "$pictures_dir" || "$pictures_dir" == "$HOME" ]]; then
    pictures_dir="$HOME/Pictures"
fi
output_dir="$pictures_dir/Screenshots"
mkdir -p "$output_dir"

/usr/bin/grim -g "$geometry" - |
    /usr/bin/satty --filename - \
        --output-filename "$output_dir/screenshot-%Y%m%d-%H%M%S-%f.png" \
        --initial-tool arrow \
        --copy-command '/usr/bin/wl-copy --type image/png' \
        --actions-on-enter save-to-clipboard \
        --actions-on-escape exit \
        --floating-hack --resize smart --early-exit all
