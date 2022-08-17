 #!/bin/bash

zcat "$log_file" | cc_log_convert | awk '$2=="r" && $17=="video/mp4" {print $1, $13}' > Results

regions=$(cat Results | awk '{print $1}' | xargs iptool | cut -d ' ' -f 2}
bitrate=$(zcat Regions | awk '{print $2}' | cut -d "/" -f 11 )

results=$(paste <(echo "$regions") <(echo "$bitrate"))

sorted_results=$(cat "$results" | sort | uniq -c | sort -rn)

cat "$sorted_results"

