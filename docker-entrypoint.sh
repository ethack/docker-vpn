#!/bin/sh

if [ ! -s /root/.ssh/authorized_keys ]; then
    if [ -z "${AUTHORIZED_KEYS}" ]; then
        echo "Need your ssh public key as AUTHORIZED_KEYS env variable. Abnormal exit ..."
        exit 1
    fi

    echo "Populating /root/.ssh/authorized_keys with the value from AUTHORIZED_KEYS env variable ..."
    echo "${AUTHORIZED_KEYS}" > /root/.ssh/authorized_keys
fi

# echo "Generating new host keys as necessary..."
# ssh-keygen -A

echo "Starting the ssh daemon..."
# add -D -e to start in interactive mode with debugging output
/usr/sbin/sshd

# Execute the CMD from the Dockerfile:
exec "$@"

