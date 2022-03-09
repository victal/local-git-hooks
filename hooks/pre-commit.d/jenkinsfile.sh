#!/usr/bin/env bash

CURRENT_SCRIPT="${BASH_SOURCE[0]}"
CURRENT_ENV="${CURRENT_SCRIPT%.*}.env"
if [ -f "$CURRENT_ENV" ];
then
   . "$CURRENT_ENV"
fi

JENKINSFILE_PATTERN='^jenkinsfile$'

# Response output in case of valid Jenkinsfile
CORRECT_VALIDATION_MESSAGE="Jenkinsfile successfully validated."

function validate_jenkinsfile() {
    local JENKINSFILE="$1"
    local JENKINS_CRUMB
    local RESULT
    echo "Validating $JENKINSFILE"
    JENKINS_CRUMB=$(curl --insecure -u "$JENKINS_USER:$JENKINS_PASSWD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)" 2>/dev/null)
   curl --insecure -X POST -u "$JENKINS_USER:$JENKINS_PASSWD" -H "$JENKINS_CRUMB" -F "jenkinsfile=<$JENKINSFILE" "$JENKINS_URL/pipeline-model-converter/validate"
    RESULT=$(curl --insecure -X POST -u "$JENKINS_USER:$JENKINS_PASSWD" -H "$JENKINS_CRUMB" -F "jenkinsfile=<$JENKINSFILE" "$JENKINS_URL/pipeline-model-converter/validate" 2>/dev/null)

    # see https://stackoverflow.com/questions/613572 for why quotes are needed
    echo "Result: '$RESULT'"

    if [ "$RESULT" != "$CORRECT_VALIDATION_MESSAGE" ]
    then
        exit 1
    fi
}

MODIFIED_JENKINSFILES=$(git diff --name-only --staged | grep -i "${JENKINSFILE_PATTERN}")

if [ -n "$MODIFIED_JENKINSFILES" ]; then
   echo 'Validating changed Jenkinsfiles' 
   for JENKINSFILE in $MODIFIED_JENKINSFILES; do
      validate_jenkinsfile "$JENKINSFILE"
   done
fi

