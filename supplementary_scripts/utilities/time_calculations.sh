#!/bin/bash

# Check if both start_time and end_time are provided as arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <start_time> <end_time>"
  exit 1
fi

# Extract start_time and end_time from command line arguments
start_time="$1"
end_time="$2"

# Extract date and time components
start_date="${start_time:0:8}"
start_time="${start_time:9}"

end_date="${end_time:0:8}"
end_time="${end_time:9}"

# Extract year, month, day, hour, minute, and second components
start_year="${start_date:0:4}"
start_month="${start_date:4:2}"
start_day="${start_date:6:2}"
start_hour="${start_time:0:2}"
start_minute="${start_time:2:2}"
start_second="${start_time:4:2}"

end_year="${end_date:0:4}"
end_month="${end_date:4:2}"
end_day="${end_date:6:2}"
end_hour="${end_time:0:2}"
end_minute="${end_time:2:2}"
end_second="${end_time:4:2}"

# Create timestamp strings in a format that can be parsed by 'date'
start_timestamp="$start_year-$start_month-$start_day $start_hour:$start_minute:$start_second"
end_timestamp="$end_year-$end_month-$end_day $end_hour:$end_minute:$end_second"

# Convert start_time and end_time to Unix timestamps
unix_start_time=$(date -d "$start_timestamp" +%s)
unix_end_time=$(date -d "$end_timestamp" +%s)

# Calculate the difference in seconds
time_difference=$((unix_end_time - unix_start_time))

# Calculate the number of days, hours, minutes, and seconds
days=$((time_difference / 86400))  # 86400 seconds in a day
time_difference=$((time_difference % 86400))
hours=$((time_difference / 3600))
time_difference=$((time_difference % 3600))
minutes=$((time_difference / 60))
seconds=$((time_difference % 60))

# Print the difference
echo "Time elapsed: $days days, $hours hours, $minutes minutes, $seconds seconds"
