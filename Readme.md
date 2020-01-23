
## About

Traditionally when connecting to a VPN, you install the VPN software on your host system and connect. The software then may route all of your host's traffic through the VPN. You change your routes, but some VPN software is pretty heavy handed with re-adding routes. This is overkill and undesirable if all you want is to access only a few services behind the VPN. Sending all your traffic through a VPN has privacy concerns and can slow down your internet connection to the speed of your VPN.

docker-vpn will connect to a remote VPN endpoint within a container and start an SSH server in the same container. You can connect to the SSH server and use normal port forwarding flags like:
- `-D 1080` - Starts a socks5 proxy on port 1080. Connections using this proxy will be tunneled through SSH into the container and then tunneled to the remote network through the VPN client.
- `-L 80:remote.example.com:80` - Forwards port 80 on remote.example.com so that you can access it from localhost:80.
- `-J root@localhost:2222 user@remote.example.com` - Uses docker-vpn as an SSH jump host to SSH to remote.example.com. (Requires OpenSSH 7.3)

## Usage

The following VPN clients are currently available. I may add more if I find the need.
- `openvpn` provides an OpenVPN client.
- `openconnect` provides a Cisco AnyConnect or Juniper Pulse client.

### Build

```bash
docker build -t vpn .
```

### Examples

All the parameters after the `openvpn` or `openconnect` are parameters for the VPN client. Adjust these based on your individual VPN server's settings.

You **must** include authorized keys so that you can authenticate via SSH into the container. You can do this by setting the `AUTHORIZED_KEYS` environment variable or by mapping an `authorized_keys` file into the container to `/root/.ssh/authorized_keys`.

Connect to an OpenVPN server using a configuration file and a username and password. Store your configuration file at ~/.vpn/client.ovpn on your host and create ~/.vpn/user.creds that contains your username on the first line and your password on the second line of the file. If you have two factor authentication, it will prompt you for your second factor.

```bash
export AUTHORIZED_KEYS="$(cat ~/.ssh/id_rsa.pub)"
docker run -it --rm --cap-add=NET_ADMIN --device /dev/net/tun -e AUTHORIZED_KEYS -v ~/.vpn:/vpn -p 2222:22 vpn openvpn --auth-retry interact --config /vpn/client.ovpn --auth-user-pass /vpn/user.creds
```

Connect to a Cisco VPN server located at https://remote.vpn and prompt for credentials.

```bash
export AUTHORIZED_KEYS="$(cat ~/.ssh/id_rsa.pub)"
docker run --rm -it --cap-add=NET_ADMIN --device /dev/net/tun -e AUTHORIZED_KEYS -p 2222:22 vpn openconnect https://remote.vpn
```

A docker-compose file would be very useful to store frequently used configurations. Here are equivalents for the above docker commands.
```yaml
version: '3'

services:
  openvpn:
    image: vpn
    build:
      context: .
      dockerfile: Dockerfile
    cap_add:
      - net_admin
    devices:
      - /dev/net/tun
    environment:
      - AUTHORIZED_KEYS
    ports:
      - '2222:22'
    command: ["openvpn", "--config", "/vpn/client.ovpn", "--auth-user-pass", "/vpn/user.creds", "--auth-retry", "interact"]
    volumes:
      - ~/.vpn:/vpn

  openconnect:
    image: vpn
    build:
      context: .
      dockerfile: Dockerfile
    cap_add:
      - net_admin
    devices:
      - /dev/net/tun
    environment:
      - AUTHORIZED_KEYS
    ports:
      - '2222:22'
    command: ["openconnect", "https://remote.vpn"]
```

You'd then use these with:
```bash
export AUTHORIZED_KEYS="$(cat ~/.ssh/id_rsa.pub)"
docker-compose run --rm --service-ports openvpn
docker-compose run --rm --service-ports openconnect
```

Another option could be to set up shell aliases.
```bash
alias openvpn="docker run -it --rm --cap-add=NET_ADMIN --device /dev/net/tun -v ~/.vpn:/vpn -P -e AUTHORIZED_KEYS=\"$(cat ~/.ssh/id_rsa.pub)\" vpn openvpn"
alias openconnect="docker run -it --rm --cap-add=NET_ADMIN --device /dev/net/tun -P -e AUTHORIZED_KEYS=\"$(cat ~/.ssh/id_rsa.pub)\" vpn openconnect"
```

And then you would pass arguments exactly like you would to the normal VPN clients, with the difference being any paths you specify would be wherever you mounted your files into the docker container:
```bash
openvpn --auth-retry interact --config /vpn/client.ovpn --auth-user-pass /vpn/user.creds
openconnect https://remote.vpn
```

In the alias the port to use will be mapped at random to avoid conflicts. You can use `docker ps` to see which port on localhost to SSH to.

## Limitations
- If you have multiple VPNs you want to connect to at once, you have to choose ports that do not conflict.
- VPN configurations can be wildly different. I created these to make my specific use case easier. Other configurations may require passing in your own command line options and adding your own volume mounts.

## Future Plans
- Find a way to support split tunneling so that VPN traffic can be routed through the docker container while non-VPN traffic can go out your default gateway. Likely with custom routes and iptables rules, or by somehow sharing the tun adapter with the container and the host. VPNs can support split tunneling natively, but I'd rather not fight with their configurations directly.

## Credits
- https://github.com/Praqma/alpine-sshd
- https://github.com/vimagick/dockerfiles/blob/master/openconnect/Dockerfile
