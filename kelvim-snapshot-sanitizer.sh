#!/bin/bash

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--domain)
            input_domain="$2"
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

checkpoints=($(sudo virsh checkpoint-list $input_domain | awk 'NR>2 {print $1}'))

for checkpoint in "${checkpoints[@]}"; do
    echo $checkpoint
done