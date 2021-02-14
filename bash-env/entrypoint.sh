#!/usr/bin/env sh
echo "hello from entrypoint!"
export ENTRYPOINT=YES
exec "$@"