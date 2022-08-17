#!/bin/bash

#log selection from directory 
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

#setting variables
#analysis time, cut from filename
log_time=$(printf "$log_file" | cut -d "-" -f 5)
modified_log_time=${log_time::-3}
log_date=$(date -d @"$modified_log_time")

#log date, cut from filename
log_digits=$(printf "$log_file" | cut -d "-" -f 2)
log_year=$(printf "$log_digits" | cut -c 1-4)
log_month=$(printf "$log_digits" | cut -c 5-6)
log_day=$(printf "$log_digits" | cut -c 7-8)
log_hr=$(printf "$log_digits" | cut -c 9-12)
log_day=$(printf "$log_day/$log_month/$log_year time: $log_hr")


printf "Please type in the HostNames to analyse separated by a space with no commas.\n"
read hostnames

#loop through hostname list //simple grep// 
for hostname in $hostnames
do
        printf "==================================================="
        printf "\n\nHostname: "
        printf "$hostname"

        printf "\n\nlog date:$log_day"
        printf "\n\n == Response Times == \n"
        
		#edge response time awk
		printf "\nEdge:\n"
        zcat $log_file | grep "$hostname" | awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="r" && !($16~/[jfGKPX]/ || $53~/m/) && !($11~/^(10\.|127\.0\.0\.1)/) {sum=($4+$5+$6+$7)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n

		#parent response time awk
        printf "\nParent:\n"
        zcat $log_file | grep "$hostname" |  awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="f" && $19!~/o/ {sum=($4+$5+$6+$7+$8)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n

		#origin response time awk
        printf "\nOrigin:\n"
        zcat $log_file | grep "$hostname" |  awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="f" && $19~/o/ {sum=($4+$5+$6+$7+$8)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n

		#top 10 urls with host header and client IP
        printf "____________________________________________________"
        printf "\n\nTop 10 URL´s with host header and client IP.\n\n"
        zcat $log_file | grep "$hostname" | cc_log_convert | awk '$2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) && $14=="200" {print $13, $18}' | sort | uniq -c | sort -nr | head -10

		#user agent list sorted
        printf "____________________________________________________"
        printf "\n\nUser Agent List.\n\n"
        zcat $log_file | grep "$hostname" | cc_log_convert | awk '$2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $21}' | sort | uniq -c | sort -nr | head -10

        printf "\n\n"
done
