#! /bin/bash

# Load domain names into an array
readarray -t domain_array < <(sudo virsh list --all | awk 'NR>2 && $2 != "" {print $2}')

# Date string used to create the right folder
date_string=$(date +"%y%m%d")

# External backup media
ext_backup_media="/mnt/elemento-vault/snaps"

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
        echo -e "\tBlock device target: $target, source: $source"

        # Check if the source contains a folder ending with ".elimg"
        if [[ "$source" =~ .*/[^/]+\.elimg(/|$) ]]; then
            echo -e "\tSource is placed in a '.elimg'. Creating snapshots alongside."
            elimg_path=$(echo "$source" | awk -F'/[^/]*\.elimg' '{print $1 "/.elimg"}')
            echo -e "\t\tmkdir -p $elimg_path/snaps/$date_string"
            echo -e "\t\tvirtnbdbackup -d $domain -l auto -o $elimg_path/snaps/$date_string -i $target"
            # Operation A (e.g., creating a snapshot, logging, etc.)
        else
            echo -e "\tSource locally mounted. Creating snapshots on external backup media $ext_backup_media."
            # Operation B (e.g., copying files, notifying, etc.)
        fi
    done
done
