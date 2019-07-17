FROM alpine:edge

RUN apk add --no-cache \
   --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
   openconnect

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh", "openconnect"]
EXPOSE 8000
