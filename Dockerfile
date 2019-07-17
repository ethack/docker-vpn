FROM alpine:edge

RUN apk add --no-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
    openconnect \
    && apk add --no-cache openvpn

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8000
