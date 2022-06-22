#!/bin/bash

#Select a log file from the current directory
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

#Aquire the log time of the first line
log_time=$(zcat $log_file | awk '$2=="r" {print $3}' | head -1 | cut -d "." -f 1)
log_date=$(date -d @"$log_time")

#User to input the hostnames
printf "Please type in the HostNames to analyse separated by a space with no commas.\n"
read hostnames

#User to input the agent IP Address to grep for 
printf "Please type in the IP address or CIDR that you want to grep for.\n"
read cidr

#output log date
printf "\n\n Log Date: $log_date. "
for hostname in $hostnames
do
        printf "\n\nHostname:"
        printf "$hostname"
		
		#Grab request ID of a succesfull 2xx R line request
        printf "\n\nRequest ID of sucessful 2xx request:\n"
        req_id=$(zcat $log_file | grep "$hostname" | grep "$cidr" | awk '$2=="r" && $14=="200" {print $32}' | head -1)
        
		#If there is no succesful 200 r line request then state as much and grab any R line with any status
		if [ -z "$req_id" ];
        then
                r_line=$(zcat $log_file | grep "$hostname" | grep "$cidr" | awk '$2=="r" {print $0}' | head -1)
				
				#if there is no r line then state as much, else print the r line
				if [ -z "$r_line" ];
				then
					printf "There are no lines for this request. Sorry"
				else
					printf "There are no requests that returned an R line with status 200.\n\n"
					printf "Aquiring R line with any status code.\n\n"
					echo "$r_line"
				fi	
        
		#If there was a succesful R line then grep for the request ID and output results
		else
                printf "$req_id\n\n"
                printf "log lines:\n\n"
                zcat $log_file | grep "$req_id"
        fi
done
