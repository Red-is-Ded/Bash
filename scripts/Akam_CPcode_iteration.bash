#!/bin/bash
for cpcode in 763667 763671 841659 830872 830877 822748 861829 904882 1052285 1070924 1075309
do
        echo ""
        echo ""
        echo "================"
        echo "Date: 27th May"
        echo "================"
        echo ""
        echo ""
        echo "Checking $cpcode"
        echo ""
        echo "R line"
        echo ""
        echo ""
        zcat CP763667-202205271200-104.125.80.80-637-1653664502.gz | grep "$cpcode" | awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="r" && !($16~/[jfGKPX]/ || $53~/m/) && !($11~/^(10\.|127\.0\.0\.1)/) {sum=($4+$5+$6+$7)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n
        echo ""
        echo ""
        echo "F Line"
        zcat CP763667-202205271200-104.125.80.80-637-1653664502.gz | grep "$cpcode" |  awk -v OFS='\t' 'BEGIN {split("0 1 2 3 5 8 10 15 20 30 60 100",B)}$2=="f" && $19~/o/ {sum=($4+$5+$6+$7+$8)/1000;pos=0;k++; for(p in B){if(sum >=B[p] && B[p]>pos){pos=B[p]}};A[pos]++}END {for (i in A) { printf("%4s %10d %2.5f \n", i"s", A[i], A[i]*100/k"%");}}'|sort -n
        echo ""
        echo ""
done
