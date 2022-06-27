#!/bin/bash

# Select the log file from the log files in the current directory.
log_choices=(CP*)
printf "Chose one of the following logs for analysis\n"
select log_file in "${log_choices[@]}"
do
    if ! [ "$log_file" ]
    then
        printf "Choose one of the available files.\n"
        continue
    fi
    printf "$log_file has been selected\n"
    break
done

# Input CP code list
printf "Please type in the CP codes to analyse separated by a space with no commas, eg. 12834 84848 85585 93939 94949\n"
read cp_codes

# Iterate through the list of CP codes and run the following commands.
for cp_code in $cp_codes
do

        #Add all token expiry times to an array called token_expiry, format for datestamp
        readarray -t token_expiry < <(zcat $log_file| grep -E "ERR_ACCESS_DENIED|SHORT_TOKEN_INVALID\|$cp_code" | awk '$2=="S" {print $31}' | cut -d "=" -f 4 | cut -d "%" -f 1)

        #Add all request times to an array called req_time, format for datestamp
        readarray -t req_time < <(zcat $log_file| grep -E "ERR_ACCESS_DENIED|SHORT_TOKEN_INVALID\|$cp_code" | awk '$2=="S" {print $3}' | cut -d "." -f 1)

        #Initialise counter
        count=0
        #Iterate through the token_expiry array
        max=${#token_expiry[@]}
        echo max is $max
        for i in $(seq 0 $max)
        do
                #compare the token expiry datestamp to the req_time datestamp for the same index
                #echo token_expiry is "${token_expiry[$i]}"
                #echo req time is "${req_time[$i]}"

                if [ "${token_expiry[$i]}" -gt "${req_time[$i]}" ]
                then
                        #If the token_index entry is less, then increment counter by one
                        (( count++ ))
                else
                        :
                fi
        #print total number of occurences where the token expiry was less than the request datestamp.
        done
        printf "\n for CP code $cp_code there were $count instances of expired authentication tokens."
done
