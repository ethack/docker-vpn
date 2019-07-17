
## About

Traditionally when connecting to a VPN, you install the VPN software on your host system and connect. The software then may route all of your host's traffic through the VPN. This is overkill and undesirable if all you want is to access a single service behind the VPN. Sending all your traffic through a VPN has privacy concerns and can slow down your internet connection to the speed of your VPN.

These Dockerfiles allow connecting to a single TCP service that sits behind a VPN. They act very similar to SSH port forwarding, and if your service is an SSH server then you can also do SSH port forwarding tunneled through this to access additional ports.

## Usage

The following services are currently available. I may add more if I find the need.
- `openvpn` provides an OpenVPN client.
- `openconnect` provides a Cisco AnyConnect or Juniper Pulse client.

### Build
```bash
docker build -t vpn .
```

### Examples
In all the scenarios below, you need to replace HOST=ip and PORT=port with the IP and port behind the VPN that you wish to connect to. It will be available on the localhost:2222, but if you want it listening on a different port just change the 2222 in the command to whatever you want.

All the parameters after the `openvpn` or `openconnect` are parameters for the VPN client. Adjust these based on your individual VPN server's settings.

Connect to an OpenVPN server using a configuration file and a username and password. Store your configuration file at ~/.vpn/client.ovpn on your host and create ~/.vpn/user.creds that contains your username on the first line and your password on the second line of the file. If you have two factor authentication, it will prompt you for your second factor.
```bash
docker run -it --rm --cap-add=NET_ADMIN --device /dev/net/tun -v ~/.vpn:/vpn -p 2222:8000 -e HOST=ip -e PORT=port vpn openvpn --auth-retry interact --config /vpn/client.ovpn --auth-user-pass /vpn/user.creds
```

Connect to a Cisco VPN server located at https://remote.vpn and prompt for credentials.
```bash
docker run --rm -it --cap-add=NET_ADMIN --device /dev/net/tun -p 2222:8000 -e HOST=ip -e PORT=port vpn openconnect https://remote.vpn
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
      - HOST
      - PORT
    ports:
      - 2222:8000
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
      - HOST
      - PORT
    ports:
      - 2222:8000
    command: ["openconnect", "https://remote.vpn"]
```

You'd then use these with:
```bash
HOST=ip PORT=port docker-compose run --rm --service-ports openvpn
HOST=ip PORT=port docker-compose run --rm --service-ports openconnect
```

Another option could be to set up shell aliases.
```bash
alias openvpn="docker run -it --rm --cap-add=NET_ADMIN --device /dev/net/tun -v ~/.vpn:/vpn -P -e HOST=$HOST -e PORT=$PORT vpn openvpn"
alias openconnect="docker run --rm -it --cap-add=NET_ADMIN --device /dev/net/tun -P -e HOST=$HOST -e PORT=$PORT vpn openconnect"
```

And then you would pass arguments exactly like you would to the normal VPN clients, with the difference being any paths you specify would be wherever you mounted your files into the docker container:
```bash
HOST=ip PORT=port openvpn --auth-retry interact --config /vpn/client.ovpn --auth-user-pass /vpn/user.creds
HOST=ip PORT=port openconnect https://remote.vpn
```

In the alias the port to use will be mapped at random to avoid conflicts. You must use `docker ps` to see which port on localhost to connect to.

## Limitations
- If you have multiple VPNs you want to connect to at once, you have to choose ports that do not conflict.
- This only allows a connection to one host and service behind a VPN. This can be extended manually by modifying the entrypoint script and listening on an additional port or by using SSH port forwarding if you have access to an SSH service behind your VPN.
- VPN configurations can be wildly different. I created these to make my specific use case easier. Other configurations may require passing in your own command line options and adding your own volume mounts.

## Future Plans
- Find a way to support split tunneling so that VPN traffic can be routed through the docker container while non-VPN traffic can go out your default gateway. Likely with custom routes and iptables rules, or by somehow sharing the tun adapter with the container and the host. VPNs can support split tunneling natively, but I'd rather not fight with their configurations directly.
