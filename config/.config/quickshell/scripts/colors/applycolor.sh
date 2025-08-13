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

# Function to increase saturation of a hex color
increase_saturation() {
  local hex_color="$1"
  local saturation_boost="${2:-30}"  # Default boost of 30%
  
  # Remove # if present
  hex_color="${hex_color#\#}"
  
  # Convert hex to RGB
  local r=$((16#${hex_color:0:2}))
  local g=$((16#${hex_color:2:2}))
  local b=$((16#${hex_color:4:2}))
  
  # Convert RGB to HSL using bc for floating point arithmetic
  local max min delta h s l
  max=$(echo "scale=6; if ($r >= $g && $r >= $b) $r else if ($g >= $b) $g else $b" | bc)
  min=$(echo "scale=6; if ($r <= $g && $r <= $b) $r else if ($g <= $b) $g else $b" | bc)
  delta=$(echo "scale=6; $max - $min" | bc)
  
  # Lightness
  l=$(echo "scale=6; ($max + $min) / 2 / 255" | bc)
  
  # Saturation and Hue
  if (( $(echo "$delta == 0" | bc -l) )); then
    s=0
    h=0
  else
    if (( $(echo "$l < 0.5" | bc -l) )); then
      s=$(echo "scale=6; $delta / ($max + $min)" | bc)
    else
      s=$(echo "scale=6; $delta / (510 - $max - $min)" | bc)
    fi
    
    # Calculate hue
    if (( $(echo "$max == $r" | bc -l) )); then
      h=$(echo "scale=6; (($g - $b) / $delta) * 60" | bc)
    elif (( $(echo "$max == $g" | bc -l) )); then
      h=$(echo "scale=6; ((($b - $r) / $delta) + 2) * 60" | bc)
    else
      h=$(echo "scale=6; ((($r - $g) / $delta) + 4) * 60" | bc)
    fi
    
    if (( $(echo "$h < 0" | bc -l) )); then
      h=$(echo "scale=6; $h + 360" | bc)
    fi
  fi
  
  # Increase saturation
  s=$(echo "scale=6; $s + ($saturation_boost / 100)" | bc)
  if (( $(echo "$s > 1" | bc -l) )); then
    s=1
  fi
  
  # Convert HSL back to RGB
  local c=$(echo "scale=6; (1 - (2 * $l - 1)^2)^0.5 * $s" | bc -l)
  local x=$(echo "scale=6; $c * (1 - (($h / 60) % 2 - 1)^2)^0.5" | bc -l)
  local m=$(echo "scale=6; $l - $c / 2" | bc)
  
  local r1 g1 b1
  local h_sector=$(echo "scale=0; $h / 60" | bc)
  
  case $h_sector in
    0) r1=$c; g1=$x; b1=0 ;;
    1) r1=$x; g1=$c; b1=0 ;;
    2) r1=0; g1=$c; b1=$x ;;
    3) r1=0; g1=$x; b1=$c ;;
    4) r1=$x; g1=0; b1=$c ;;
    *) r1=$c; g1=0; b1=$x ;;
  esac
  
  # Final RGB values
  r=$(echo "scale=0; ($r1 + $m) * 255" | bc)
  g=$(echo "scale=0; ($g1 + $m) * 255" | bc)
  b=$(echo "scale=0; ($b1 + $m) * 255" | bc)
  
  # Ensure values are in 0-255 range
  r=$(echo "if ($r > 255) 255 else if ($r < 0) 0 else $r" | bc)
  g=$(echo "if ($g > 255) 255 else if ($g < 0) 0 else $g" | bc)
  b=$(echo "if ($b > 255) 255 else if ($b < 0) 0 else $b" | bc)
  
  # Convert back to hex
  printf "%02x%02x%02x" "$r" "$g" "$b"
}

apply_qt() {
  sh "$CONFIG_DIR/scripts/kvantum/materialQT.sh"          # generate kvantum theme
  python "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py" # apply config colors
}

apply_openrgb() {
  # Find primary color value for OpenRGB
  primary_color=""
  for i in "${!colorlist[@]}"; do
    if [[ "${colorlist[$i]}" == "\$primary" ]]; then
      primary_color="${colorvalues[$i]#\#}"  # Remove # if present
      break
    fi
  done
  
  if [ -n "$primary_color" ]; then
    # Increase saturation for OpenRGB (makes colors more vibrant)
    saturated_color=$(increase_saturation "$primary_color" 40)
    # Apply saturated color to OpenRGB with static mode
    openrgb -c "$saturated_color" --mode static 2>/dev/null || true
  fi
}

apply_hypr() {
  # Update Hyprland colors.conf with term6 value for fullscreen border color
  HYPR_COLORS_FILE="$HOME/.config/hypr/hyprland/colors.conf"
  
  if [ -f "$HYPR_COLORS_FILE" ]; then
    # Find term6 value for hyprland border color
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
apply_openrgb &
