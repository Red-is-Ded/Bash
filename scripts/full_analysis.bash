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

#Aquire the log time of the first line
log_time=$(zcat $log_file | awk '$2=="r" {print $3}' | head -1 | cut -d "." -f 1)
log_date=$(date -d @"$log_time")

#User to input the CP codes
printf "Please type in the CP codes to analyse separated by a space with no commas, eg. 12834 84848 85585 93939 94949\n"
read cp_codes

# User to select analysis modes.
printf "\nPlease select the analysis mode you wish to run\n"
printf "0. Response Time analysis.\n"
printf "1. Status code analysis.\n"
printf "2. Count of r Lines, S lines, f lines reporting a certain status code.\n"
printf "3. Top 10 ghost IPs reporting r lines, and the count of r lines for each.\n"
printf "4. Top 10 URLs being requested from the origin and top 10 URLs with the largest objects sizes.\n"
printf "5. URL´s served and object status for a certain status code.\n"
printf "6. Top 200 status URLs at Edge with host header and client IP.\n"
printf "7. Origin and Edge hits per minute.\n"
printf "8. Grab Sample log lines for a hostname and Client IP address or CIDR.\n"

read a_mode

# ==== Functions ====

# Response Time Analysis
response_time () {
        printf "\n\nR Line - Response Times (Edge)\n"
        zcat $log_file | grep "$cp_code" | awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="r" && !($16~/[jfGKPX]/ || $53~/m/) && !($11~/^(10\.|127\.0\.0\.1)/) {sum=($4+$5+$6+$7)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n

        printf "\n\nF Line - Response Times(Origin)\n\n"
        zcat $log_file | grep "$cp_code" |  awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="f" && $19~/o/ {sum=($4+$5+$6+$7+$8)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n

        printf "\n\nF Line - Response Times(Parent)\n\n"
        zcat $log_file | grep "$cp_code" |  awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="f" && $19!~/o/ {sum=($4+$5+$6+$7+$8)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n

}

# Response Code Analysis
status_analysis () {
        printf "\n\nEdge Response Codes\n\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="S" && !($18~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $16,$32}; $2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $14, $15}' | sort | uniq -c | sort -nr | awk '{array[$2" "$3]=$1; sum+=$1} END { for (i in array) printf "%s %d %3.3f%%\n", i, array[i], array[i]/sum*100}' | sort -rn -k3,3 | column -t -s' '

        printf "\n\nOrigin Response Codes (Origin)\n\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="f" && $19~/o/ {print $15, $30}' | sort | uniq -c | sort -nr | awk '{array[$2" "$3]=$1; sum+=$1} END { for (i in array) printf "%s %d %3.3f%%\n", i, array[i], array[i]/sum*100}' | sort -rn -k3,3 | column -t -s' '

        printf "\n\nOrigin Response Codes (Parent)\n\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="f" && $19!~/o/ {print $15, $30}' | sort | uniq -c | sort -nr | awk '{array[$2" "$3]=$1; sum+=$1} END { for (i in array) printf "%s %d %3.3f%%\n", i, array[i], array[i]/sum*100}' | sort -rn -k3,3 | column -t -s' '
}

# Line Count with and without staus
count () {
        printf  "\n\nUnfiltered S Lines:\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="S"' | wc -l

        printf "\n\nUnfiltered f lines:\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="f"' | wc -l

        printf "\n\nUnfiltered r lines:\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="r"' | wc -l

        printf "\n\nTo search for line counts for a specific status please enter line type: either S f or r:\n"
        read line_type

        printf "\nPlease enter status code, for example 404.\n"
        read c_status

        if [ $line_type == "f" ] || [ $line_type == "r" ]
        then
                zcat $log_file | grep "$cp_code" |cc_log_convert | awk '$2=="$line_type" && $14=="$c_status"' | wc -l
        elif [ $line_type == "S" ]
        then
                zcat $log_file | grep "$cp_code" |cc_log_convert| awk '$2=="r" && $14=="$c_status"' | wc -l
        else
                printf "\nPlease enter valid line type, either r, f or S, They are case sensitive.\n"
        fi
}

# Top 10 ghost IPs
top_ips () {
        printf "\nTop 10 ghost IPs reporting r lines, and the count of r lines for each:\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="r" {print $11}' | sort | uniq -c | sort -nr | head -10
        printf "\n\nIncluding S lines\n"
        zcat $log_file | grep "$cp_code" | cc_log_convert | awk '$2=="r" {print $11}' | sort | uniq -c | sort -nr | head -10
}

# Top URLS
top_urls () {
        printf "\n\nTop 10 URLs being requested from the origin:\n\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="f" && $19~/o/ {print $14}' | sort | uniq -c | sort -nr | head -10

        printf "\n\nTop 10 or 20 URLs with the largest objects sizes:\n\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="r" {print $8, $13}' | uniq | sort -rn | head -10
}

#URL´s served and object status for a certain status code
url_served () {
        printf  "\nPlease select a status code you would like to search for:\n"
        read u_status

        printf  "\nURLs served with $u_status (Edge)\n"
        zcat $log_file | grep "$cp_code" | cc_log_convert | awk '$2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) && $14=="$u_status" {print $13}' | sort | uniq -c | sort -nr | head -50

        printf "\nURLs served with 404 (Forward side-Origin):\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="f" && $19~/o/ && $15=="404" {print $28}' | sort | uniq -c | sort -nr | head -50

        printf "\nObject status for requests served with $u_status:\n"
        zcat $log_file | grep "$cp_code" | cc_log_convert | awk '$2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) && $14=="$u_status" {print $16}' | sort | uniq -c | sort -nr
}

#Print top 200 status URLs at Edge with host header and client IP
top_200 () {
        printf "\nTop 200 status URLs at Edge with host header and client IP\n"
        zcat $log_file | grep "$cp_code" | cc_log_convert | awk '$2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) && $14=="200" {print $13, $18}' | sort | uniq -c | sort -nr | head -10
}

#Edge and Origin hits per minute
origin_edge_hits () {
        printf "\nEdge hits per minute:\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="S" && !($18~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $3}; $2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $3}' | time_convert --format="%H:%M" | sort | uniq -c

        printf "\nEdge hits per second:\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="S" && !($18~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $3}; $2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $3}' | time_convert --format="%H:%M:%S" | sort | uniq -c

        printf "\nOrigin hits per minute:\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="f" && $19~/o/ {print $3}'| time_convert --format="%H:%M" | sort | uniq -c

        printf "\nOrigin hits per second:\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="f" && $19~/o/ {print $3}'| time_convert --format="%H:%M:%S" | sort | uniq -c
}

#Grab Sample log lines
sample () {
	#User to input the hostnames
	printf "Please type in the HostNames to analyse separated by a space with no commas.\n"
	read hostnames

	#User to input the agent IP Address to grep for 
	printf "Please type in the IP address or CIDR that you want to grep for.\n"
	read cidr

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
						printf "\nThere are no lines for this request. Sorry\n"
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
}

for cp_code in $cp_codes
do
        printf "\n\n================\n"
        printf "$log_date"
        printf "\n================\n\n"
        printf "Checking $cp_code\n"

        if [ $a_mode == 0 ]
        then
                response_time

        elif [ $a_mode == 1 ]
        then
                status_analysis

        elif [ $a_mode == 2 ]
        then
                count

        elif [ $a_mode == 3 ]
        then
                top_ips

        elif [ $a_mode == 4 ]
        then
                top_urls

        elif [ $a_mode == 5 ]
        then
                url_served

        elif [ $a_mode == 6 ]
        then
                top_200

        elif [ $a_mode == 7 ]
        then
                origin_edge_hits
		
		elif [ $a_mode == 8 ]
        then
                sample

        else
                printf "\nPlease select a correct analysis mode.\n"
        fi
done