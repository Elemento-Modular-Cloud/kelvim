#! /bin/bash

# Load domain names into an array
readarray -t domain_array < <(sudo virsh list --all | awk 'NR>2 {print $2}')

# Iterate over the array
for domain in "${domain_array[@]}"; do
    echo "Processing domain: $domain"
    # Add your processing logic here
done
