#!/usr/bin/env bash

RED=$(tput setaf 160)
BOLD=$(tput bold)
RESET=$(tput sgr0)

CURRENT_SCRIPT="${BASH_SOURCE[0]}"
CURRENT_ENV="${CURRENT_SCRIPT%.*}.env"
if [ -f "$CURRENT_ENV" ];
then
   . "$CURRENT_ENV"
fi

KUBERNETES_API_VERSION=${KUBERNETES_API_VERSION:-1.19}
MANIFEST_FILE_PATTERN="${MANIFEST_FILE_PATTERN:-kubernetes.*\.ya*ml$}"

MODIFIED_MANIFESTS=$(git diff --name-only --staged | grep -i "${MANIFEST_FILE_PATTERN}")

if [ -n "$MODIFIED_MANIFESTS" ]; then
   if type kubeconform >/dev/null 2>&1;
   then
      echo "Kubeconform installed. Checking changed kubernetes manifests"
      kubeconform -kubernetes-version "${KUBERNETES_API_VERSION}" -strict -verbose "$MODIFIED_MANIFESTS"
      RETCODE=$?
      if [ $RETCODE -ne 0 ]
      then
         echo "${RED}${BOLD}ERROR:${RESET} Errors were found in kubernetes manifests. Check the output for errors/warnings."
         exit $RETCODE
      fi
   elif type kubeval > /dev/null 2>&1; 
   then
      echo "Kubeval installed. Checking changed kubernetes manifests"
      kubeval --strict "$MODIFIED_MANIFESTS"
      RETCODE=$?
      if [ $RETCODE -ne 0 ]
      then
         echo "${RED}${BOLD}ERROR:${RESET} Errors were found in kubernetes manifests. Check the output for errors/warnings."
         exit $RETCODE
      fi
   else
      echo "Kubeval not installed. Skipping kubernetes manifest validation"
   fi
fi
