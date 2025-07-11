# General
## Aliases
alias whatsapp elecwhat
alias zen zen-browser
alias editor gnome-text-editor

alias ls 'eza --icons'
alias tree 'eza --icons --tree'

## Abbreviations
abbr --add yay 'yay -Sy'
abbr --add install 'yay -Sy'
abbr --add update 'yay -Syu --noconfirm'

abbr --add gs "git status"
abbr --add ga "git add ."
abbr --add gc "git commit -m"


# CTFs and stuff
## Aliases
alias ligolo '/usr/share/ligolo/linux/proxy/amd64/proxy -selfcert'
alias penelope '/opt/penelope/penelope.py -i tun0'

## Functions
function bloodhound
    set oldpwd (pwd)
    cd ~/.config/bloodhound
    docker compose up -d
    cd $oldpwd
end

## Abbreviations
abbr --add nmap 'sudo nmap --min-rate 10000'
abbr --add ovpn 'sudo openvpn'

## Variables
set -x rockyou '/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt'

## Executables



