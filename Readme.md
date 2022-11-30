## About

docker-vpn is an alternative to installing VPN software on your host system and routing all your traffic through a VPN. This is useful if you want to have control over which traffic is sent through the VPN. Sending all your traffic through a VPN is a privacy concern and limits your internet connection to the speed of your VPN.

The [`ethack/vpn`](https://hub.docker.com/r/ethack/vpn) Docker image and accompanying shell script provide the following:
- OpenVPN client
- Cisco AnyConnect or Juniper Pulse client
- SSH server (default port 2222) with public key authentication enabled and configured
- SOCKS 5 server (default port 1080)
- SSH config file entry created for each VPN connection

## Install

- [Install Docker](https://docs.docker.com/install/) using the instructions or use `curl -fsSL https://get.docker.com -o get-docker.sh | sh` if you have a supported linux distro and like to live dangerously.
- Source `vpn.sh` in your `.bashrc` file or current shell. E.g. `source vpn.sh`

## Usage

```
# openvpn NAME [OpenVPN args...]
# e.g.
openvpn foo https://vpn.example.com

# openconnect NAME [OpenConnect args...]
# e.g.
openconnect bar https://vpn.example.com
```

The first argument is an arbitrary name that you give your VPN connection. This is used in the Docker container names and the SSH config file. The rest of the arguments are passed to the VPN client. Each example above will connect to a VPN located at vpn.example.com.

Once connected, you will see a message telling you which ports are available and the name of the ssh config profile.

```
============================================
SSH Port: 2222
SOCKS Proxy Port: 1080
Use: ssh foo
============================================
```

I recommend using a proxy switcher browser extension like one of the following. This allows you to quickly switch proxies on/off or tunnel certain websites through a proxy while letting all other traffic go through your default gateway.
* Proxy SwitchyOmega [[source]](https://github.com/FelisCatus/SwitchyOmega) [[Chrome]](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif) [[Firefox]](https://addons.mozilla.org/en-US/firefox/addon/switchyomega/)
* FoxyProxy Standard [[source]](https://github.com/foxyproxy/firefox-extension) [[Firefox]](https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/)

### OpenVPN Config File

```
openvpn foo
```

To connect to the `foo` VPN put your config file at `~/.vpn/foo.ovpn` and then you can run `openvpn foo` to automatically use the corresponding config file.

You can optionally put your credentials in `~/.vpn/foo.creds`. The username goes on the first line and the password on the second line. This gives up some security for the convenience of not having to enter your username and password. You will still be prompted for your 2FA code if your VPN endpoint requires it. You can run `chmod 600 ~/.vpn/foo.creds` to ensure only the file owner can read it.

### OpenConnect Profile

OpenConnect offers an additional interactive command `openconnect_new_profile` which will guide you through a creation of a configuration profile. Once created, the profile is saved in `~/.vpn/NAME.profile` and `~/.vpn/NAME.secret`. To connect using a profile you can simply use `openconnect NAME` and the VPN connection will be established without any interaction. Currently the following options are supported:

- Hostname & optional port
- Username authentication
  - with password
  - without password
  - with password & external 2-factor authentication
- Connection group

## Customizing

You can customize options by setting the following environment variables. The defaults are shown below.

* `BIND_INTERFACE`: 127.0.0.1
* `SSH_PORT`: 2222
* `SOCKS_PORT`: 1080
* `AUTHORIZED_KEYS`: Any keys allowed to SSH as the current user to the current machine, any keys configured in `ssh-agent`, and any keys found in `~/.ssh/*.pub`.

### Advanced Forwarding

docker-vpn provides all the power of an OpenSSH server. For example:

* Dynamic port forwarding (SOCKS proxy) `ssh -D 1080 foo` - Starts a socks5 proxy on port 1080. Connections using this proxy will be tunneled through SSH into the container and then tunneled to the `foo` network through the VPN client.
* Local port forwarding `ssh -L 8080:private.foo.com:80 foo` - Forwards port 80 on private.foo.com so that you can access it from localhost:8080.
* Jump hosts `ssh -J foo user@private.foo.com` - Allows connecting via SSH to a remote server private.foo.com that is not directly accessible but is accessible by using the docker-vpn `foo` as a jump host. (Requires OpenSSH 7.3)
* TUN/TAP support - SSH has [builtin tunneling support](https://wiki.archlinux.org/index.php/VPN_over_SSH#OpenSSH's_built_in_tunneling). This is similar to just connecting directly with OpenVPN or OpenConnect software, but gives you the power (and responsibility) to configure your own routing.

## Limitations
- If you have multiple VPNs you want to connect to at once, you have to choose ports that do not conflict.
- VPN configurations can be wildly different. I created these to make my specific use case easier. Other configurations may require passing in your own command line options and adding your own volume mounts.

## Credits
- https://github.com/Praqma/alpine-sshd
- https://github.com/vimagick/dockerfiles/blob/master/openconnect/Dockerfile
