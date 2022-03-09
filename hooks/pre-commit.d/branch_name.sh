#!/usr/bin/env bash
set -x

CURRENT_SCRIPT="${BASH_SOURCE[0]}"
CURRENT_ENV="${CURRENT_SCRIPT%.*}.env"
if [ -f "$CURRENT_ENV" ];
then
   . "$CURRENT_ENV"
fi

if [ -z "${MAIN_BRANCH}" ];
then
    MAIN_BRANCH="master"
fi

if ! git branch --list | grep -q "${MAIN_BRANCH}";
then
    echo "Main branch ${MAIN_BRANCH} not found for project. Ignoring hook"
    exit 0
fi

if [ -z "${VALID_BRANCH_REGEX}" ];
then
    VALID_BRANCH_REGEX="^(feat|fix)\/LIV-[0-9]+/[a-z0-9._-]+$"
fi

LOCAL_BRANCH="$(git branch --show-current)"
COMMIT_NUM=$(git log --oneline "${MAIN_BRANCH}..${LOCAL_BRANCH}" | wc -l)

# Blocking commits only for new branches
if [ "${COMMIT_NUM}" -eq "0" ] && [ "${LOCAL_BRANCH}" != "${MAIN_BRANCH}" ];
then
    MESSAGE="Invalid branch name being created: ${LOCAL_BRANCH}.
    Branch names in this project must adhere to this contract: ${VALID_BRANCH_REGEX}.
    Your commit will be rejected. You should rename your branch to a valid name and try again."

    if [[ ! ${LOCAL_BRANCH} =~ ${VALID_BRANCH_REGEX} ]]
    then
        echo "${MESSAGE}"
        exit 1
    fi
fi

exit 0
