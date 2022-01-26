#!/bin/bash

# This script disables, deletes or archives users..

ARCHIVE_DIR="/archive"

# Display the usage and exit.
useage() {
  echo "Useage: ${0} [-dra] [USER]..."
  echo "Disable or delete user accounts"
  echo "-d Deletes accounts instead of disabling them."
  echo "-r Removes the home directory associated with the account/s."
  echo "-a Creates an archive of the home directories of associated account/s in /archives."
  echo "-help Displays the help dialogue."
}

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo "You are not root, please run with SU priviledges" >&2
  exit 1
fi

# Parse the options.
while getopts dra OPTION
do
  case  ${OPTION} in
    d)
      DELETE_USER="true"
      ;;
    r)
      REMOVE_OPTION="-r"
      ;;
    a)
      ARCHIVE="true"
      ;;
    ?)
      useage
      ;;
  esac
done

# Remove the options while leaving the remaining arguments.
shift "$(( OPTIND -1 ))"

# If the user doesn't supply at least one argument, give them help.
if [[ "${#}" -lt 1 ]]
then
  useage
fi

# Loop through all the usernames supplied as arguments.
for USERNAME in "${@}"
do
  echo "Processing ${USERNAME}"

  # Make sure the UID of the account is at least 1000.
  USERID=$(id -u ${USERNAME})
  if [[ "${USERID}" -lt 1000 ]]
  then
    echo "Deletion of system account ${USERNAME} with user ID ${USERID} is not supported. This script will now
    exit." >&2
    exit 1
  fi

  # Create an archive if requested to do so.
  if [[ "${ARCHIVE}" = "true" ]]
  then
    # Make sure the ARCHIVE_DIR directory exists.
    if [[ ! -d "${ARCHIVE_DIR}" ]]
    then
      echo "Creating ${ARCHIVE_DIR} directory."
      mkdir -p ${ARCHIVE_DIR}
      if [[ "${?}" -ne 0 ]]
      then
        echo "The directory ${ARCHIVE_DIR} could not be created." >&2
        exit 1
      fi
    fi

    # Archive the user's home directory and move it into the ARCHIVE_DIR
    HOME_DIR="/home/${USERNAME}"
    ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tar.gz"
    if [[ -d "${HOME_DIR}" ]]
    then
      echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
      tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
      if [[ "${?}" -ne 0 ]]
      then
        echo "Could not create archive file ${ARCHIVE_FILE}." >&2
        exit 1
      fi
    else
      echo "${HOME_DIR} does not exist or is not a directory." >&2
      exit 1
    fi
  fi

  # Delete the user.
  if [[ "${DELETE_USER}" = "true" ]]
  then
    userdel ${REMOVE_OPTION} ${USERNAME}

    # Check to see if the userdel command succeeded.
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USERNAME} was NOT deleted." >&2
      exit 1
    fi
    echo "The account ${USERNAME} was deleted."
  else
    chage -E 0 ${USERNAME}

    # Check to see if the chage command succeeded.
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USERNAME} was not disabled." >&2
      exit 1
    fi
    echo "The account ${USERNAME} was disabled."
  fi
done

exit 0