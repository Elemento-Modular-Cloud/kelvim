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
if [ -z "$backup_source" ]; then
    backup_source=$(pwd)
fi

echo -e "${color_purple}\nStarting Elemento Kelvim Lister utility ($(date +"%Y-%m-%d %H:%M:%S"))${color_end}\n"

checkpoints_path="$backup_source/checkpoints"
snapshots=($(ls -1 $checkpoints_path | sort -t '.' -k 2,2n))

# Print table headers
printf "${color_orange}%-20s %-10s %-10s %-10s %-20s${color_end}\n" "Snapshot" "Kind" "Size" "Chksum" "Date"

# Iterate over the array and print each element without the .xml extension
for snapshot in "${snapshots[@]}"; do
    # Remove the .xml extension to match the data files
    base_name="${snapshot%.xml}"
    kind="inc"

    # Handle first snapshot differently since it's a full backup
    if [ "$base_name" == "virtnbdbackup.0" ]; then
        data_file="*.full.data"
        kind="full"
    else
        data_file="*.$base_name.data"
    fi

    # Check if any files match the pattern
    matched_files=($backup_source/$data_file)

    if [[ ${#matched_files[@]} -eq 0 || ! -e "${matched_files[0]}" ]]; then
        continue
    fi

    # Loop through each matched file
    for file in "${matched_files[@]}"; do
        # Get the size of the file
        size_cmd="du -h \"$file\" | awk '{print \$1}'"
        size=$(eval "$size_cmd")

        # Check if the corresponding checksum file exists
        if [[ ! -f "$file.chksum" ]]; then
            continue
        fi

        chksum_cmd="cat \"$file.chksum\""
        chksum=$(eval "$chksum_cmd")

        # Get the modification date of the file
        date_cmd="stat -c %y \"$file\""
        date=$(eval "$date_cmd")

        break
    done

    # Print table row
    printf "%-20s %-10s %-10s %-10s %-20s$\n" "$base_name" "$kind" "$size" "$chksum" "$date"
done

if ls "$backup_source"/*.copy.data 1> /dev/null 2>&1; then
    data_file="*.copy.data"
    snapshot='virtnbdbackup.0'
    kind='full'

    size_cmd="du -h $backup_source/$data_file | awk '{print \$1}'"
    size=$(eval "$size_cmd")

    chksum_cmd="cat $backup_source/$data_file.chksum"
    chksum=$(eval "$chksum_cmd")

    date_cmd="stat -c %y $backup_source/$data_file"
    date=$(eval "$date_cmd")

    printf "%-20s %-10s %-10s %-10s %-20s$\n" "$snapshot" "$kind" "$size" "$chksum" "$date"
fi

if ls "$backup_source"/*.full.data 1> /dev/null 2>&1; then
    data_file="*.full.data"
    snapshot='virtnbdbackup.0'
    kind='full'

    size_cmd="du -h $backup_source/$data_file | awk '{print \$1}'"
    size=$(eval "$size_cmd")

    chksum_cmd="cat $backup_source/$data_file.chksum"
    chksum=$(eval "$chksum_cmd")

    date_cmd="stat -c %y $backup_source/$data_file"
    date=$(eval "$date_cmd")

    printf "%-20s %-10s %-10s %-10s %-20s$\n" "$snapshot" "$kind" "$size" "$chksum" "$date"
fi
