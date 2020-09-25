FROM alpine:edge

RUN apk add --no-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
    openconnect \
    && apk add --no-cache openvpn openssh \
    && apk add --no-cache py3-pip \
    && pip --no-cache-dir install pproxy supervisor

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