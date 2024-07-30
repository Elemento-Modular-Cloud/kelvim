#! /bin/bash

# Load domain names into an array
readarray -t domain_array < <(sudo virsh list --all | awk 'NR>2 && $2 != "" {print $2}')

# Iterate over the array
for domain in "${domain_array[@]}"; do
    echo "Processing domain: $domain"
    
    # Get block devices and load into an array
    readarray -t blk_array < <(sudo virsh domblklist "$domain" | awk 'NR>2 && $1 != "" {print $1 " " $2}')
    
    # Iterate over the block devices array and print the name and source
    for blk in "${blk_array[@]}"; do
        # Split each line into target and source
        target=$(echo $blk | awk '{print $1}')
        source=$(echo $blk | awk '{print $2}')
        echo "\tBlock device target: $target, source: $source"
    done
done
