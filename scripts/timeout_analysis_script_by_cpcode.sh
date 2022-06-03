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

log_time=$(printf "$log_file" | cut -d "-" -f 5)
modified_log_time=${log_time::-3}
log_date=$(date -d @"$modified_log_time")

printf "Please type in the CP codes to analyse separated by a space with no commas, eg. 12834 84848 85585 93939 94949\n"
read cp_codes

for cp_code in $cp_codes
do
        printf "\n\n================\n"
        printf "$log_date"
        printf "\n================\n\n"
        printf "Checking $cp_code"

        printf "\n\nR Line - Response Times\n"
        zcat $log_file | grep "$cp_code" | awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="r" && !($16~/[jfGKPX]/ || $53~/m/) && !($11~/^(10\.|127\.0\.0\.1)/) {sum=($4+$5+$6+$7)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n

        printf "\n\nEdge Response Codes\n\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="S" && !($18~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $16,$32}; $2=="r" && !($16~/[ftGKPX]/) && !($11~/^(10\.|127\.0\.0\.1)/) {print $14, $15}' | sort | uniq -c | sort -nr | awk '{array[$2" "$3]=$1; sum+=$1} END { for (i in array) printf "%s %d %3.3f%%\n", i, array[i], array[i]/sum*100}' | sort -rn -k3,3 | column -t -s' '

        printf "\n\nF Line - Response Times\n\n"
        zcat $log_file | grep "$cp_code" |  awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="f" && $19~/o/ {sum=($4+$5+$6+$7+$8)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n

        printf "\n\nOrigin Response Codes\n\n"
        zcat $log_file | grep "$cp_code" | awk '$2=="f" && $19~/o/ {print $15, $30}' | sort | uniq -c | sort -nr | awk '{array[$2" "$3]=$1; sum+=$1} END { for (i in array) printf "%s %d %3.3f%%\n", i, array[i], array[i]/sum*100}' | sort -rn -k3,3 | column -t -s' '
        printf "\n\n"
done