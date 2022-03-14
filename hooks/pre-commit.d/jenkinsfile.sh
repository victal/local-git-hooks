#!/usr/bin/env bash

REQUIRED_VARS=(JENKINS_USER JENKINS_PASSWD JENKINS_URL)

CURRENT_SCRIPT="${BASH_SOURCE[0]}"
CURRENT_ENV="${CURRENT_SCRIPT%.*}.env"
if [ -f "$CURRENT_ENV" ];
then
   . "$CURRENT_ENV"
fi

function check_required_vars() {
   local MISSING_VARS=""
   for i in "${REQUIRED_VARS[@]}" ; do
      if [[ -z "${!i}" ]]; then
         MISSING_VARS="${MISSING_VARS} ${i}"
      fi
   done
   if [[ -n "${MISSING_VARS}" ]]; then
      echo "Required vars missing at ${CURRENT_ENV}: ${MISSING_VARS}"
      exit 1
   fi
}

check_required_vars

# Configurations with default values
JENKINSFILE_PATTERN="${JENKINSFILE_PATTERN:-jenkinsfile$}"
JENKINS_REQUEST_TIMEOUT=${JENKINS_REQUEST_TIMEOUT:-5}

# Response output in case of valid Jenkinsfile
CORRECT_VALIDATION_MESSAGE="Jenkinsfile successfully validated."

function handle_curl_timeout() {
   echo "Request to Jenkins timed out. Skipping hook"
   exit 0
}

function validate_jenkinsfile() {
   local JENKINSFILE="$1"
   local JENKINS_CRUMB
   local RESULT
   local JENKINS_CREDENTIALS="$JENKINS_USER:$JENKINS_PASSWD"
   local JENKINS_CRUMB_URL="$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)"
   local JENKINS_VALIDATE_URL="$JENKINS_URL/pipeline-model-converter/validate"

   echo "Validating $JENKINSFILE"
   JENKINS_CRUMB=$(curl --insecure -m "${JENKINS_REQUEST_TIMEOUT}" -u "${JENKINS_CREDENTIALS}" "$JENKINS_CRUMB_URL" 2>/dev/null)
   if [[ $? -eq 28 ]]; then
      handle_curl_timeout
   fi
   RESULT=$(curl --insecure -m "${JENKINS_REQUEST_TIMEOUT}" -X POST -u "${JENKINS_CREDENTIALS}" -H "$JENKINS_CRUMB" -F "jenkinsfile=<$JENKINSFILE" "$JENKINS_VALIDATE_URL" 2>/dev/null)
   if [[ $? -eq 28 ]]; then
      handle_curl_timeout
   fi

    # see https://stackoverflow.com/questions/613572 for why quotes are needed
    echo "Result: '$RESULT'"

    if [ "$RESULT" != "$CORRECT_VALIDATION_MESSAGE" ]
    then
       exit 1
    fi
 }

MODIFIED_JENKINSFILES=$(git diff --name-status --staged | grep -v '^D' | awk "BEGIN{IGNORECASE = 1} /${JENKINSFILE_PATTERN}/{print \$2} END{}")

if [ -n "$MODIFIED_JENKINSFILES" ]; then
   echo 'Validating changed Jenkinsfiles' 
   for JENKINSFILE in $MODIFIED_JENKINSFILES; do
      validate_jenkinsfile "$JENKINSFILE"
   done
fi
