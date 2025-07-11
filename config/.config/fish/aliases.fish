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
set -x weblist '/home/chsoares/Repos/ezpz/utils/weblist_ezpz.txt'

## Executables
alias ligolo '/usr/share/ligolo/linux/proxy/amd64/proxy -selfcert'
alias penelope '/opt/penelope/penelope.py -i tun0'

## ezpz
#set -U EZPZ_HOME '/home/chsoares/Repos/ezpz' 
#set -U fish_function_path "$EZPZ_HOME/functions" $fish_function_path
