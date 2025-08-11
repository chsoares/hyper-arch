#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

term_alpha=100 #Set this to < 100 make all your terminals transparent
# sleep 0 # idk i wanted some delay or colors dont get applied properly
if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

colornames=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f1)
colorstrings=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=($colornames)     # Array of color names
colorvalues=($colorstrings) # Array of color values

# Troca os valores de $term1 e $term2
idx1=-1
idx2=-1
for i in "${!colorlist[@]}"; do
    [[ "${colorlist[$i]}" == "\$term2" ]] && idx1=$i
    [[ "${colorlist[$i]}" == "\$term3" ]] && idx2=$i
done

if [[ $idx1 -ge 0 && $idx2 -ge 0 ]]; then
    tmp="${colorvalues[$idx1]}"
    colorvalues[$idx1]="${colorvalues[$idx2]}"
    colorvalues[$idx2]="$tmp"
fi

apply_term() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$CONFIG_DIR"/scripts/terminal/sequences.txt ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$CONFIG_DIR"/scripts/terminal/sequences.txt "$STATE_DIR"/user/generated/terminal/sequences.txt
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
  done

  sed -i "s/\$alpha/$term_alpha/g" "$STATE_DIR/user/generated/terminal/sequences.txt"

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
}

apply_qt() {
  sh "$CONFIG_DIR/scripts/kvantum/materialQT.sh"          # generate kvantum theme
  python "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py" # apply config colors
}

apply_hypr() {
  # Update Hyprland colors.conf with term6 value for fullscreen border color
  HYPR_COLORS_FILE="$HOME/.config/hypr/hyprland/colors.conf"
  
  if [ -f "$HYPR_COLORS_FILE" ]; then
    # Find term6 value
    term6_value=""
    for i in "${!colorlist[@]}"; do
      if [[ "${colorlist[$i]}" == "\$term6" ]]; then
        term6_value="${colorvalues[$i]#\#}"  # Remove # if present
        break
      fi
    done
    
    if [ -n "$term6_value" ]; then
      # Update the fullscreen windowrulev2 border color
      sed -i "s/windowrulev2 = bordercolor rgba([^)]*), fullscreen:1/windowrulev2 = bordercolor rgba(${term6_value}AA), fullscreen:1/g" "$HYPR_COLORS_FILE"
    fi
  fi
}

apply_qt &
apply_term &
apply_hypr &
