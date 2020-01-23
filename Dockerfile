FROM alpine:edge

RUN apk add --no-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
    openconnect \
    && apk add --no-cache openvpn openssh

# create the root user's .ssh directory
# modify the ssh server config to allow desired features
# unlock the root account (TODO generate a random root password)
# and finally generate host keys
RUN mkdir /root/.ssh \
    && chmod 0700 /root/.ssh \
    && sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config \
    && sed -i 's/^GatewayPorts no/GatewayPorts clientspecified/' /etc/ssh/sshd_config \
    && sed -i 's/^root:!::0:::::/root:::0:::::/' /etc/shadow \
    && ssh-keygen -A
# Note we generate SSH keys in the image to avoid getting conflicts every time we start
# a new container. But this means you have to rebuild the image to get unique host keys.

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 22