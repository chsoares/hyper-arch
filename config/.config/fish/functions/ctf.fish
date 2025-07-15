function ctf_header
    echo (set_color yellow --bold)"  "$argv(set_color normal)
end
function ctf_info
    echo (set_color cyan)"  "$argv(set_color normal)
end
function ctf_cmd
    echo (set_color blue)"  "$argv(set_color normal)
end
function ctf_error
    echo (set_color red --bold)"  "$argv(set_color normal)
end
function ctf_warn
    echo (set_color magenta --bold)"  "$argv(set_color normal)
end
function ctf_success
    echo (set_color magenta --bold)"  "$argv(set_color normal)
end
function ctf_question
    echo (set_color magenta)"  "$argv(set_color normal)
end

function start
    # === 1. Dependency check ===
    set -l dependencies ntpd gnome-text-editor
    for dep in $dependencies
        if not type -q $dep
            ctf_error "Dependency '$dep' not found in PATH."
            return 1
        end
    end

    # === 2. Argument validation ===
    if test (count $argv) -ne 2
        ctf_error "Usage: start <boxname> <boxip>"
        return 1
    end

    set -l box $argv[1]
    set -l ip $argv[2]
    set -l base_dir ~/Lab/labs
    set -l box_dir $base_dir/$box
    set -l box_dir_zero $base_dir/0_$box

    # === 3. IP validation ===
    if not string match -rq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' -- $ip
        ctf_error "Invalid IP address: $ip"
        return 1
    end

    # === 4. If box directory already exists ===
    if test -d $box_dir
        ctf_info "Box directory already exists: $box_dir"
        cd $box_dir

        if test -f env.fish
            ctf_info "Sourcing environment variables from env.fish"
            source env.fish
        else
            ctf_warn "env.fish not found in $box_dir"
        end

        if test -f hosts.bak
            ctf_info "Restoring /etc/hosts from hosts.bak"
            sudo cp hosts.bak /etc/hosts
        else
            ctf_warn "hosts.bak not found in $box_dir"
        end

        # Move to 0_$box if not already there
        if not test -d $box_dir_zero
            mv $box_dir $box_dir_zero
            ctf_info "Moved $box_dir to $box_dir_zero"
            cd $box_dir_zero
        else
            cd $box_dir_zero
        end

        ctf_header "Box '$box' environment restored!"
        return 0
    end

    # === 5. If box directory does NOT exist ===
    set -l arch_ip (ip a | grep tun0 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -n1)
    set -l url "http://$box.htb"
    set -l boxpwd $box_dir_zero

    mkdir -p $boxpwd
    cd $boxpwd

    # Generate env.fish
    echo "set -x arch $arch_ip" > env.fish
    echo "set -x box $box" >> env.fish
    echo "set -x ip $ip" >> env.fish
    echo "set -x url $url" >> env.fish
    echo "set -x boxpwd $boxpwd" >> env.fish

    # Export variables to session
    source env.fish
    cp env.fish ~/Lab/env.fish

    ctf_info "Created directory at $boxpwd"
    ctf_info "\$arch is set to $arch"
    ctf_info "\$ip is set to $ip"
    ctf_info "\$box is set to $box"
    ctf_info "\$url is set to $url"

    # Add to /etc/hosts
    if grep -q "^$ip" /etc/hosts
        sudo sed -i "/^$ip/s/\$/ $box.htb/" /etc/hosts
        ctf_info "Appended $box.htb to existing entry for $ip in /etc/hosts"
    else
        echo "$ip    $box.htb" | sudo tee -a /etc/hosts > /dev/null
        ctf_info "Added new entry $ip $box.htb to /etc/hosts"
    end
    grep "^$ip" /etc/hosts --color=never

    # Sync time
    ctf_info "Syncing time with target box (ntpd -q -g -n $ip)"
    sudo ntpd -q -g -n -p $ip

    ctf_success "Happy hacking! 😉"
end