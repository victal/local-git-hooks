#!/usr/bin/env sh

# See https://git-scm.com/docs/githooks#_prepare_commit_msg for
# definitions of these variables
COMMIT_MESSAGE_SOURCE="$2"

if [ "${COMMIT_MESSAGE_SOURCE}" != "message" ]; then
    echo "Not running commitizen on commit message from source: ${COMMIT_MESSAGE_SOURCE}"
    exit 0
fi

if type commitlint >/dev/null 2>&1;
then
    if commitlint -x "$(npm root -g)/@commitlint/config-conventional" -q -e;
    then
        echo "Commit message already matches lint rules. Skipping commitizen prompt."
        exit 0
    fi
fi

if type git-cz >/dev/null 2>&1;
then
    exec < /dev/tty && npx cz --hook || true
else
    echo "Commitizen not found! Install it using 'npm install -g commitizen to use this hook'"
fi
