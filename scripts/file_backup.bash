 #!/bin/bash
 
 3 log() {
   # This function sends a message to syslog and to STDOUT if VERBOSE is true.
   local MESSAGE="${@}"
   if [[ "${VERBOSE}" = "true" ]]
   then
     echo "${MESSAGE}"
   fi
   logger -t luser-demo10.sh "${MESSAGE}"
 }
 
 backup_file() {
   # This function creates a backup of a file. Returns a non-zero status on
   # error.
   local FILE="${1}"
 
   # Make sure the file exists.
   if [[ -f "${FILE}" ]]
   then
     local BACKUP_FILE="/var/tmp/$(basename ${FILE}).$(date +%F-%N)"
     log "Backing up ${FILE} to ${BACKUP_FILE}."
 
     # The exit status of the function will be the exit status of the cp
     # command.
     cp -p ${FILE} ${BACKUP_FILE}
   else
 
     # The file does not exist, so return a non-zerio exit status.
     return 1
   fi
 }
 
 readonly VERBOSE="true"
 log "Hello"
 log "This is Fun"
 
 backup_file "/etc/passwd"
 
 # Make a desicion based on the exit status of the function.
 if [[ "${?}" -eq 0 ]]
 then
   log "The file backup succeded."
 else
   log "file backup failed"
   exit 1
 fi