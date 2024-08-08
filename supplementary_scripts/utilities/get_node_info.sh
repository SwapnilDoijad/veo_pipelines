#!/bin/bash

nodes_info=$(scontrol show node)

echo "$nodes_info" | awk '
BEGIN {
    print "NodeID\tCPUs\tMemory\tPartitions"
}
/^NodeName=/ {
    # Extract Node ID
    split($1, a, "=")
    node_id = a[2]

    # Initialize variables
    cpus = "N/A"
    memory = "N/A"
    partitions = "N/A"
}
/CPUTot=/ {
    # Extract CPUs
    split($1, a, "=")
    cpus = a[2]
}
/RealMemory=/ {
    # Extract Memory
    split($1, a, "=")
    memory = a[2]
}
/Partitions=/ {
    # Extract Partitions
    split($1, a, "=")
    partitions = a[2]
}
/^\s*$/ {
    # Print details for the current node
    print node_id "\t" cpus "\t" memory "\t" partitions
}
'
