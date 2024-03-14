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
    local httpProxyPort="${HTTP_PROXY_PORT:-1088}"
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
    dockerCmd+=("--publish" "$bindIf:$httpProxyPort:3128")
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
    if [ -f "$vpnConfig/$vpnName.env" ]; then
        dockerCmd+=("--env-file" "$vpnConfig/$vpnName.env")
    fi
    if [ -f "$vpnConfig/$vpnName.hosts" ]; then
        while IFS= read -r line; do
          # Skip commented lines and empty lines
          case "$line" in
              \#* | "")
                  continue
                  ;;
          esac
          hostname=$(echo "$line" | awk '{print $2}')
          ip=$(echo "$line" | awk '{print $1}')
          dockerCmd+=("--add-host" "$ip:$hostname")
        done < "$vpnConfig/$vpnName.hosts"
    fi
    # add custom mounts
    if [ -f "$vpnConfig/$vpnName.mounts" ]; then
        while IFS= read -r line; do
          # Skip commented lines and empty lines
          case "$line" in
              \#* | "")
                  continue
                  ;;
          esac
          file_remote=$(echo "$line" | awk '{print $2}')
          file_local=$(echo "$line" | awk '{print $1}')
          dockerCmd+=("--mount" "type=bind,src=$file_local,dst=$file_remote,readonly=true")
        done < "$vpnConfig/$vpnName.mounts"
    fi
    dockerCmd+=("$dockerImage")

    # append any extra args provided
    vpnCmd+=("$@")
    # display help if there are no arguments at this point
    if [ ${#vpnCmd[@]} -eq 1 ]; then
        vpnCmd+=("--help")
    fi

    setup-ssh-config.d
    ssh-config "$vpnName" "$sshPort" > "$HOME/.ssh/config.d/vpn-$vpnName"

    echo "============================================"
    echo "SSH Port: $sshPort (customize with SSH_PORT)"
    echo "SOCKS Proxy Port: $socksPort (customize with SOCKS_PORT)"
    echo "HTTP Proxy Port: $httpProxyPort (customize with HTTP_PROXY_PORT)"
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
    local httpProxyPort="${HTTP_PROXY_PORT:-1088}"
    local sshPort="${SSH_PORT:-2222}"
    local authorizedKeys="${AUTHORIZED_KEYS}"
    
    local vpnConfig="$HOME/.vpn"
    local vpnProfile="$vpnConfig/$vpnName.profile"
    local vpnSecret="$vpnConfig/$vpnName.secret"
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
    dockerCmd+=("--interactive")
    dockerCmd+=("--cap-add" "NET_ADMIN")
    dockerCmd+=("--device" "/dev/net/tun")
    dockerCmd+=("--publish" "$bindIf:$sshPort:22")
    dockerCmd+=("--publish" "$bindIf:$socksPort:1080")
    dockerCmd+=("--publish" "$bindIf:$httpProxyPort:3128")
    dockerCmd+=("--env" "AUTHORIZED_KEYS=$authorizedKeys")
    if [ -f "$vpnConfig/$vpnName.xml" ]; then
        dockerCmd+=("--mount" "type=bind,src=$vpnConfig/$vpnName.xml,dst=/vpn/config,readonly=true")
        vpnCmd+=("--xmlconfig" "/vpn/config")
    fi
    if [ -f "$vpnConfig/$vpnName.config" ]; then
        dockerCmd+=("--mount" "type=bind,src=$vpnConfig/$vpnName.config,dst=/vpn/openconnect.config,readonly=true")
        vpnCmd+=("--config" "/vpn/openconnect.config")
    fi
    if [ -f "$vpnConfig/$vpnName.env" ]; then
        dockerCmd+=("--env-file" "$vpnConfig/$vpnName.env")
    fi
    if [ -f "$vpnConfig/$vpnName.hosts" ]; then
        while IFS= read -r line; do
          # Skip commented lines and empty lines
          case "$line" in
              \#* | "")
                  continue
                  ;;
          esac
          hostname=$(echo "$line" | awk '{print $2}')
          ip=$(echo "$line" | awk '{print $1}')
          dockerCmd+=("--add-host" "$ip:$hostname")
        done < "$vpnConfig/$vpnName.hosts"
    fi
    # add custom mounts
    if [ -f "$vpnConfig/$vpnName.mounts" ]; then
        while IFS= read -r line; do
          # Skip commented lines and empty lines
          case "$line" in
              \#* | "")
                  continue
                  ;;
          esac
          file_remote=$(echo "$line" | awk '{print $2}')
          file_local=$(echo "$line" | awk '{print $1}')
          dockerCmd+=("--mount" "type=bind,src=$file_local,dst=$file_remote")
        done < "$vpnConfig/$vpnName.mounts"
    fi

    if [ -f "${vpnProfile}" ]; then
        source "${vpnProfile}"
        vpnCmd+=("${OC_HOST}")
        vpnCmd+=("--user" "${OC_USER}")

        if [ -f "${vpnSecret}" ]; then
            vpnCmd+=("--passwd-on-stdin")
        else
            vpnCmd+=("--no-passwd")
        fi
        if ! [ -z "{$OC_GROUP}" ]; then
            vpnCmd+=("--authgroup" "${OC_GROUP}")
        fi
    fi

    # append any extra args provided
    vpnCmd+=("$@")
    # display help if there are no arguments at this point
    if [ ${#vpnCmd[@]} -eq 1 ]; then
        vpnCmd+=("--help")
    fi

    setup-ssh-config.d
    ssh-config "$vpnName" "$sshPort" > "$HOME/.ssh/config.d/vpn-$vpnName"
    chmod 600 "$HOME/.ssh/config.d/vpn-$vpnName"

    echo "============================================"
    echo "SSH Port: $sshPort (customize with SSH_PORT)"
    echo "SOCKS Proxy Port: $socksPort (customize with SOCKS_PORT)"
    echo "HTTP Proxy Port: $httpProxyPort (customize with HTTP_PROXY_PORT)"
    echo "Use: ssh $vpnName"
    echo "============================================"

    if [ -f "${vpnSecret}" ]; then
        dockerCmd+=("--interactive")
        dockerCmd+=("$dockerImage")
        cat "${vpnSecret}" - | "${dockerCmd[@]}" "${vpnCmd[@]}"
    else
        dockerCmd+=("--interactive" "--tty")
        dockerCmd+=("$dockerImage")
        "${dockerCmd[@]}" "${vpnCmd[@]}"
    fi
}

openconnect_new_profile() {
    echo "This tool will create automatic OpenConnect profile to allow automatic connections"
    echo

    echo -n "Name for the profile: "
    read -r vpnProfile
    if ! [[ "${vpnProfile}" =~ ^[A-Za-z0-9_]+$ ]]; then
        echo "Profile name should only contain letters, numbers, and underscores!"
        return 1
    fi
    local vpnProfilePath="$HOME/.vpn/${vpnProfile}.profile"
    if [[ -f "${vpnProfilePath}" ]]; then
        echo "Profile \"${vpnProfile}\" already exists in ${vpnProfilePath}"
        return 1
    fi

    echo -n "Hostname: "
    read -r vpnHost

    echo -n "Port [443]: "
    read -r vpnPort

    echo -n "Username: "
    read -r vpnUser

    echo -n "Password: "
    read -s -r vpnPass
    echo

    local vpnHostPort="${vpnHost}"
    if [[ ! -z "${vpnPort}" ]]; then
        vpnHostPort+="${vpnPort}"
    fi
    echo
    echo "Some VPNs require group code. Go to https://${vpnHostPort}/ and see if there's a \"GROUP\" dropdown present. It will show all possible group codes. If there's no such dropdown leave this field empty."
    echo -n "Group: "
    read -r vpnGroup

    echo
    echo "If your VPN requires two-factor authentication you need to specify its type. Usually it will be one of the following: pin, push, phone, sms. If your VPN doesn't use 2FA leave this field empty."
    echo -n "2FA Type: "
    read -r vpn2FaType

    printf "OC_HOST=%q\n" "${vpnHostPort}" >> "${vpnProfilePath}"
    printf "OC_USER=%q\n" "${vpnUser}" >> "${vpnProfilePath}"
    printf "OC_GROUP=%q\n" "${vpnGroup}" >> "${vpnProfilePath}"

    local vpnSecretPath="$HOME/.vpn/${vpnProfile}.secret"
    echo "${vpnPass}" > "${vpnSecretPath}"
    if ! [ -z "${vpn2FaType}" ]; then
       echo "${vpn2FaType}" >> "${vpnSecretPath}"
    fi

    chmod 0400 "${vpnProfilePath}"
    chmod 0400 "${vpnSecretPath}"

    echo
    echo "Your new profile has been saved in ${vpnProfilePath} and ${vpnSecretPath}"
    echo "Connect by typing: openconnect ${vpnProfile}"
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
