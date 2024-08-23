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

checkpoints_path="$backup_source/checkpoints"

snapshots=$(ls -1 $checkpoints_path | sort -t '.' -k 2,2n)

# Iterate over the array and print each element without the .xml extension
for snapshot in "${snapshots[@]}"; do
    echo "${snapshot%.xml}"
done