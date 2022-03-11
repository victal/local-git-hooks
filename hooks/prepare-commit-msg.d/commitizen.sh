#!/usr/bin/env sh
echo "commitizen"
echo "$@"

exec < /dev/tty && npx cz --hook || true
