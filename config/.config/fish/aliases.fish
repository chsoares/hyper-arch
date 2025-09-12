# General
## Aliases
alias zen zen-browser
alias editor gnome-text-editor

alias ls 'eza --icons --group-directories-first'
alias tree 'eza --icons --tree --group-directories-first'

## Abbreviations
abbr --add yay 'yay -Sy'
abbr --add install 'yay -Sy'
abbr --add uninstall 'yay -R'
abbr --add update 'yay -Syu --noconfirm'

abbr --add gs "git status"
abbr --add ga "git add ."
abbr --add gc "git commit -m"


# CTFs and stuff
if test -n $CTF_HOME
    source $CTF_HOME/misc/aliases.fish 2>/dev/null
end