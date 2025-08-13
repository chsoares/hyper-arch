#!/usr/bin/env fish

# Gera o nome do arquivo
set filename (date "+%Y%m%d-%H:%M:%S").png

# Decide o output
if test -d $boxpwd
    set output_filename "$boxpwd/screenshots/satty-$filename"
else
    set output_filename "$HOME/Pictures/Screenshots"
end

grimblast --freeze save area - | satty \
    --initial-tool rectangle \
    --copy-command wl-copy \
    --output-filename $output_filename \
    --actions-on-enter "save-to-clipboard" \
    --actions-on-escape "exit" \
    --early-exit \
    --filename -