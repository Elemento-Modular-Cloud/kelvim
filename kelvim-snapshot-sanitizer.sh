#!/bin/bash

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--domain)
            input_domain="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
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

echo -e "${color_purple}\nStarting Elemento Kelvim Lister utility ($(date +"%Y-%m-%d %H:%M:%S"))${color_end}\n"

checkpoints=($(sudo virsh checkpoint-list $input_domain | awk 'NR>2 {print $1}' | sort -t '.' -k 2,2n))

for checkpoint in "${checkpoints[@]}"; do
    sudo virsh checkpoint-delete $input_domain --metadata $checkpoint
done
