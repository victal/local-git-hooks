#!/usr/bin/env sh
echo "$1"

if type git-cz >/dev/null 2>&1;
then
    exec < /dev/tty && npx cz --hook || true
else
    echo "Commitizen not found! Install it using `npm install -g commitizen to use this hook`"
fi
