#!/bin/sh

echo "Forwarding traffic to $HOST:$PORT"
nc -lk -p 8000 -e nc -- $HOST $PORT &

"$@"
