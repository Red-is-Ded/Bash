#!/bin/bash

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

log_time=$(zcat $log_file | awk '$2=="r" {print $3}' | head -1)
modified_log_time=${log_time::-3}
log_date=$(date -d @"$modified_log_time")

printf "Please type in the HostNames to analyse separated by a space with no commas.\n"
read hostnames

printf "Please type in the IP address or CIDR that you want to grep for.\n"
read cidr

printf "\n\n Log Date: $log_date. "
for hostname in $hostnames
do
        printf "\n\nHostname:"
        printf "$hostname"

        printf "\n\nRequest ID of sucessful 2xx request:\n"
        req_id=$(zcat $log_file | grep "$hostname" | grep "$cidr" | awk '$2=="r" && $14=="200" {print $32}' | head -1)
        if [ -z "$req_id" ];
        then
                printf "There are no requests that returned an R line with status 200.\n\n"
                printf "Aquiring R line with any status code.\n\n"
                zcat $log_file | grep "$hostname" | grep "$cidr" | awk '$2=="r" {print $0}' | head -1
        else
                printf "$req_id\n\n"
                printf "log lines:\n\n"
                zcat $log_file | grep "$req_id"
        fi
done
