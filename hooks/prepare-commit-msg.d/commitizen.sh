#!/usr/bin/env sh
echo "commitizen"

exec < /dev/tty && npx cz --hook || true
