FROM alpine:latest

RUN apk add --no-cache \
    --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
    openconnect \
    && apk add --no-cache openvpn openssh \
    && apk add --no-cache py3-pip \
    && apk add --no-cache bind-tools curl \
    && apk add --no-cache supervisor \
    && apk add --no-cache py3-pproxy \

# Fix Cannot open "/proc/sys/net/ipv4/route/flush": Read-only file system
# See https://serverfault.com/questions/878443/when-running-vpnc-in-docker-get-cannot-open-proc-sys-net-ipv4-route-flush 
RUN rm -f /etc/vpnc/vpnc-script \    
    && wget https://gitlab.com/openconnect/vpnc-scripts/-/raw/master/vpnc-script -O /etc/vpnc/vpnc-script \
    && chmod +x /etc/vpnc/vpnc-script
    
# create the root user's .ssh directory
# unlock the root account
RUN mkdir /root/.ssh \
    && chmod 0700 /root/.ssh \
    && sed -i 's/^root:!::0:::::/root:::0:::::/' /etc/shadow 

COPY docker-entrypoint.sh /
COPY etc/ssh/sshd_config /etc/ssh/
COPY etc/supervisord.conf /etc/

ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /etc/ssh/
EXPOSE 22
EXPOSE 1080
