FROM vimagick/openconnect

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh", "openconnect"]
