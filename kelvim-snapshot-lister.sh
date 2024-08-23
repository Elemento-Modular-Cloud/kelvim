#!/bin/bash

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -s|--source)
            backup_source="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors
color_blue='\033[94m'
color_red='\033[91m'
color_orange='\033[93m'
color_purple='\033[95m'
color_green='\033[92m'
color_end='\033[0m'

# Variables
if [ -z $backup_source ]; then
    backup_source=$(pwd)
fi

echo -e "${color_purple}\nStarting Elemento Kelvim Lister utility ($(date +"%Y-%m-%d %H:%M:%S"))${color_end}"

checkpoints_path="$backup_source/checkpoints"
snapshots=($(ls -1 $checkpoints_path | sort -t '.' -k 2,2n))

# Iterate over the array and print each element without the .xml extension
for snapshot in "${snapshots[@]}"; do
    
    # Remove the .xml extension to match the data files
    base_name="${snapshot%.xml}"

    if [ $base_name == "virtnbdbackup.0"]; then
        data_file="*.full.data"
    else
        data_file="*.$base_name.data"
    fi
    echo -e "\nHandling snapshot ${snapshot}"
    
    # Use du to get the size of files matching the pattern
    size_cmd="du -h $backup_source/$data_file | awk '{print \$1}'"
    size=$(eval "$size_cmd")
    
    chksum_cmd="cat $backup_source/$data_file.chksum"
    chksum=$(eval "$chksum_cmd")

    date_cmd="stat -c %y $backup_source/$data_file"
    date=$(eval "$date_cmd")

    echo "Size: $size"
    echo "Chksum: $chksum"
    echo "Date: $date"
done