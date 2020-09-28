#!/bin/sh

if [ -s /root/docker-vpn_keys ]; then
    echo "Copying keys to /root/.ssh/authorized_keys"
    cp -v /root/docker-vpn_keys /root/.ssh/authorized_keys
fi

if [ ! -s /root/.ssh/authorized_keys ]; then
    if [ -z "${AUTHORIZED_KEYS}" ]; then
        echo "Need your ssh public key as AUTHORIZED_KEYS env variable. Abnormal exit ..."
        exit 1
    fi

    echo "Populating /root/.ssh/authorized_keys with the value from AUTHORIZED_KEYS env variable ..."
    echo "${AUTHORIZED_KEYS}" > /root/.ssh/authorized_keys
fi

chown root /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# echo "Generating new host keys as necessary..."
# ssh-keygen -A
echo "Generating new host keys as necessary..."
ssh-keygen -A

echo "Starting supervisor..."
/usr/bin/supervisord --configuration=/etc/supervisord.conf --logfile=/dev/null

# Execute the command passed to docker (likely a VPN connection command)
exec "$@"

