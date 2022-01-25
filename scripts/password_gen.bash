#!/bin/bash

# This script generates a random password.
# The user can set the password length with -l and can add a special character
# with -s.
# Verbose mode can be enabled with -v

# Useage statement in function
useage() {
  echo "Usage: ${0} [-vs] [-l LENGTH]" >&2
  echo "Generate a random password."
  echo "-l LENGTH Specify the password length."
  echo "-s        Append a special char to the password."
  echo "-v        Increase Verbosity."
  exit 1
}

# Verbosity function
log () {
  local MESSAGE="${@}"
  if [[ "${VERBOSE}" = "true" ]]
  then
    echo "${MESSAGE}"
  fi
}

# Set a default password length
LENGTH=48

while getopts vl:s OPTION
do
  case ${OPTION} in
    v)
      VERBOSE="true"
      log "Verbose Mode on."
      ;;
    l)
      LENGTH="${OPTARG}"
      ;;
    s)
      USE_SPECIAL_CHAR="true"
      ;;
    ?)
      useage
      ;;
  esac
done

log "Generating a password."

# Password generation
PASSWORD=$(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c${LENGTH})

# Append special character if instructed by user.
if [[ "${USE_SPECIAL_CHAR}" = "true" ]]
then
  log "Selecting a special random character."
  SPECIAL_CHAR=$(echo "!·$%&/()=??¿*^¨Ç" | fold -w1 | shuf | head -c1)
  PASSWORD="${PASSWORD}${SPECIAL_CHAR}"
fi

log "Done."
log "Here is the password."

# Display Password.
echo "${PASSWORD}"

exit 0