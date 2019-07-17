FROM alpine

RUN apk add --no-cache openvpn

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh", "openvpn"]
