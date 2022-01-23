 #!/bin/bash
 
 # Script to add a new local user to a machine using command line arguments and
 # auto generate a password for the account
 
 # Check to see if the user is root.
 if [[ ${UID} -ne 0 ]]
 then
   echo " You are not root, please run this script with Super User
   priviledges." >&2
   exit 1
 fi
 
 # Check if parameters have been fed into the script, if not provide
 # useage statement and exit.
 NUMBER_OF_PARAMETERS="${#}"
 if [[ "${NUMBER_OF_PARAMETERS}" -lt 1 ]]
 then
   echo "You provided ${NUMBER_OF_PARAMETERS} command line arguments:
   Usage ${0} USER_NAME COMMENTS" >&2
   exit 1
 fi
 
 # Use the first argument as the user name for the account.
 USER_NAME=${1}
 
 # Any remaining characters will be treated as the comment.
 shift
 COMMENT=${@}
 
 # Automatically generate a password for the account.
 PASSWORD=$(date +%s%N | sha256sum | head -c48)
 
 # Create the user with the password.
 useradd -c "${COMMENT}" -m ${USER_NAME} &> /dev/null
 echo ${PASSWORD} | passwd --stdin ${USER_NAME} &> /dev/null
 
 # Check to see if useradd succeded.
 if [[ ${?} -ne 0 ]]
 then
   echo "The user creation did not succeed please try again." >&2
   exit 1
 fi
 
 # Force password change at first login.
 passwd -e ${USER_NAME} &> /dev/null
 
 # Display the username, password and hostname.
 echo "The user name is ${USERNAME}"
 echo "The password is ${PASSWORD}"
 echo "The hostname is $(hostname)."
 exit 0