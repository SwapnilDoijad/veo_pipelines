#!/bin/bash

# Get the list of nodes along with their details, including the partition
node_info=$(sinfo -N -h -o "%N %C %m %R")

# Initialize arrays to hold free and busy nodes
free_nodes=()
busy_nodes=()

# Print the raw node info for debugging
# echo "Raw node info:"
# echo "$node_info"

# Read the node_info into an array
IFS=$'\n' read -r -d '' -a node_info_array <<< "$node_info"

# Process each line to extract node information
for line in "${node_info_array[@]}"; do
    # echo "Processing line: $line" # Debugging line

    node_name=$(echo "$line" | awk '{print $1}')
    cpu_state=$(echo "$line" | awk '{print $2}')
    real_memory=$(echo "$line" | awk '{print $3}')
    partition=$(echo "$line" | awk '{print $4}')
    
    allocated=$(echo "$cpu_state" | cut -d '/' -f 1)
    idle=$(echo "$cpu_state" | cut -d '/' -f 2)
    total=$(echo "$cpu_state" | cut -d '/' -f 4)
    
    # echo "NodeName: $node_name, Allocated: $allocated, Idle: $idle, Total: $total, RealMemory: $real_memory, Partition: $partition" # Debugging line

    # Check if the node is completely free (idle)
    if [[ "$allocated" == "0" && "$idle" == "$total" ]]; then
        # Append the extracted values to the free_nodes array
        free_nodes+=("$node_name $idle $real_memory $partition")
        # echo "Added to free_nodes: $node_name $idle $real_memory $partition" # Debugging line
    # else
    #     # Append the extracted values to the busy_nodes array
    #     busy_nodes+=("$node_name $allocated $real_memory $partition")
    #     echo "Added to busy_nodes: $node_name $allocated $real_memory $partition" # Debugging line
    fi
done

rm tmp.best_free_nodes_at_draco.txt > /dev/null 2>&1
# Print the free nodes
echo "--------------------------------------------------------------------------------"
echo "Free nodes:"
for node in "${free_nodes[@]}"; do
    echo "$node" | tee -a tmp.best_free_nodes_at_draco.txt
done
echo "--------------------------------------------------------------------------------"
# Print the busy nodes
# echo "Busy nodes:"
# for node in "${busy_nodes[@]}"; do
#     echo "$node"
# done

# Find the best free node based on idle CPUs
if [ "${#free_nodes[@]}" -gt 0 ]; then
    best_free_node=$(printf "%s\n" "${free_nodes[@]}" | sort -k2 -nr | head -n 1 )
    echo "Best free node based on idle CPUs:"
    echo "$best_free_node" | tee -a tmp.best_free_nodes_at_draco.txt
fi
echo "--------------------------------------------------------------------------------"



current_free_nodes=$(awk '{print $4}' tmp.best_free_nodes_at_draco.txt | sort | uniq -c | sort -r -n -k1,1 | awk '{print $2}')

if echo "$current_free_nodes" | grep -q "^interactive$"; then
current_free_node=interactive
elif echo "$current_free_nodes" | grep -q "^standard$"; then
current_free_node=standard
else
current_free_node=$(echo "$current_free_nodes" | head -n 1)
fi

