#!/bin/bash

openvpn() {
    local vpnName="$1"; shift
    if [ -z "$vpnName" ]; then
        echo "VPN name must be provided"
        return
    fi
    # listen on localhost by default
    local bindIf="${BIND_INTERFACE:-127.0.0.1}"
    local socksPort="${SOCKS_PORT:-1080}"
    local sshPort="${SSH_PORT:-2222}"
    local authorizedKeys="${AUTHORIZED_KEYS}"
    
    local vpnConfig="$HOME/.vpn"
    local dockerImage="ethack/vpn"
    
    # AUTHORIZED_KEYS not specified. Use some defaults.
    if [ -z "$authorizedKeys" ]; then
        # add any key allowed to ssh in as the current user
        if [ -f "$HOME/.ssh/authorized_keys" ]; then
            printf -v authorizedKeys "$(cat "$HOME/.ssh/authorized_keys")\n"
        fi
        # add all keys currently registered with ssh-agent
        if command -v ssh-add >/dev/null; then
            printf -v authorizedKeys "$(ssh-add -L)\n"
        fi
        # append any public key files found in the user's .ssh directory
        authorizedKeys+=$(find "$HOME/.ssh/" -type f -name '*.pub' -exec cat {} \;)
    fi

    local dockerCmd=("docker" "run")
    local vpnCmd=("openvpn")
    dockerCmd+=("--rm" "--name" "vpn-$vpnName")
    dockerCmd+=("--hostname" "vpn-$vpnName")
    dockerCmd+=("--interactive" "--tty")
    dockerCmd+=("--cap-add" "NET_ADMIN")
    dockerCmd+=("--device" "/dev/net/tun")
    dockerCmd+=("--publish" "$bindIf:$sshPort:22")
    dockerCmd+=("--publish" "$bindIf:$socksPort:1080")
    dockerCmd+=("--env" "AUTHORIZED_KEYS=$authorizedKeys")
    if [ -f "$vpnConfig/$vpnName.ovpn" ]; then
        dockerCmd+=("--mount" "type=bind,src=$vpnConfig/$vpnName.ovpn,dst=/vpn/config,readonly=true")
        vpnCmd+=("--config" "/vpn/config")
    fi
    if [ -f "$vpnConfig/$vpnName.creds" ]; then
        dockerCmd+=("--mount" "type=bind,src=$vpnConfig/$vpnName.creds,dst=/vpn/creds,readonly=true")
        vpnCmd+=("--auth-user-pass" "/vpn/creds")
        vpnCmd+=("--auth-retry" "interact")
    fi
    dockerCmd+=("$dockerImage")

    # append any extra args provided
    vpnCmd+=($@)
    # display help if there are no arguments at this point
    if [ ${#vpnCmd[@]} -eq 1 ]; then
        vpnCmd+=("--help")
    fi

    setup-ssh-config.d
    ssh-config "$vpnName" "$sshPort" > "$HOME/.ssh/config.d/vpn-$vpnName"

    echo "============================================"
    echo "SSH Port: $sshPort (customize with SSH_PORT)"
    echo "SOCKS Proxy Port: $socksPort (customize with SOCKS_PORT)"
    echo "Use: ssh $vpnName"
    echo "============================================"

    "${dockerCmd[@]}" "${vpnCmd[@]}"
}

openconnect() {
    local vpnName="$1"; shift
    if [ -z "$vpnName" ]; then
        echo "VPN name must be provided"
        return
    fi
    # listen on localhost by default
    local bindIf="${BIND_INTERFACE:-127.0.0.1}"
    local socksPort="${SOCKS_PORT:-1080}"
    local sshPort="${SSH_PORT:-2222}"
    local authorizedKeys="${AUTHORIZED_KEYS}"
    
    local vpnConfig="$HOME/.vpn"
    local dockerImage="ethack/vpn"
    
    # AUTHORIZED_KEYS not specified. Use some defaults.
    if [ -z "$authorizedKeys" ]; then
        # add any key allowed to ssh in as the current user
        if [ -f "$HOME/.ssh/authorized_keys" ]; then
            printf -v authorizedKeys "$(cat "$HOME/.ssh/authorized_keys")\n"
        fi
        # add all keys currently registered with ssh-agent
        if command -v ssh-add >/dev/null; then
            printf -v authorizedKeys "$(ssh-add -L)\n"
        fi
        # append any public key files found in the user's .ssh directory
        authorizedKeys+=$(find "$HOME/.ssh/" -type f -name '*.pub' -exec cat {} \;)
    fi

    local dockerCmd=("docker" "run")
    local vpnCmd=("openconnect")
    dockerCmd+=("--rm" "--name" "vpn-$vpnName")
    dockerCmd+=("--hostname" "vpn-$vpnName")
    dockerCmd+=("--interactive" "--tty")
    dockerCmd+=("--cap-add" "NET_ADMIN")
    dockerCmd+=("--device" "/dev/net/tun")
    dockerCmd+=("--publish" "$bindIf:$sshPort:22")
    dockerCmd+=("--publish" "$bindIf:$socksPort:1080")
    dockerCmd+=("--env" "AUTHORIZED_KEYS=$authorizedKeys")
    dockerCmd+=("$dockerImage")

    # append any extra args provided
    vpnCmd+=($@)
    # display help if there are no arguments at this point
    if [ ${#vpnCmd[@]} -eq 1 ]; then
        vpnCmd+=("--help")
    fi

    setup-ssh-config.d
    ssh-config "$vpnName" "$sshPort" > "$HOME/.ssh/config.d/vpn-$vpnName"

    echo "============================================"
    echo "SSH Port: $sshPort (customize with SSH_PORT)"
    echo "SOCKS Proxy Port: $socksPort (customize with SOCKS_PORT)"
    echo "Use: ssh $vpnName"
    echo "============================================"

    "${dockerCmd[@]}" "${vpnCmd[@]}"
}

# Create and configure the .ssh/config.d directory if it's not already
setup-ssh-config.d() {
    if ! grep -qFi -e 'Include config.d/*' -e 'Include ~/.ssh/config.d/*' "$HOME/.ssh/config"; then
        echo >> "$HOME/.ssh/config"
        # This allows the Include to be at the end of the file (i.e. not nested in a Host directive)
        echo 'Match all' >> "$HOME/.ssh/config"
        echo 'Include config.d/*' >> "$HOME/.ssh/config"
    fi
    mkdir -p "$HOME/.ssh/config.d/"
}

# Print the SSH config entry for the given name and port
ssh-config() {
local name="$1"
local sshPort="$2"
local user="root"
local host="127.0.0.1"

cat << EOF
Host vpn-$name $name
    Hostname $host
    User $user
    Port $sshPort
    NoHostAuthenticationForLocalhost yes

EOF
}
