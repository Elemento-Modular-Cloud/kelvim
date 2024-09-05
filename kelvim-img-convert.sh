#!/bin/bash

# Colors
color_blue='\033[94m'
color_red='\033[91m'
color_orange='\033[93m'
color_purple='\033[95m'
color_green='\033[92m'
color_end='\033[0m'

get_source_image_format() {
    local source_image="$1"
    local source_image_format=$(qemu-img info "$source_image" | grep -oP '(?<=file format: ).*')
    echo "$source_image_format"
}

set_format_flag() {
    local source_image_format="$1"
    case "$source_image_format" in
        "raw")
            echo "-f raw"
            ;;
        "qcow2")
            echo "-f qcow2"
            ;;
        "vmdk")
            echo "-f vmdk"
            ;;
        *)
            echo -e "${color_red}\nUnsupported source image format: $source_image_format${color_end}\n"
            exit 1
            ;;
    esac
}

# Function to convert image with qemu-img
convert_image() {
    local args=("$@")
    local source_image=""
    local target_image=""

    echo -e "${color_purple}\nStarting image conversion...${color_end}\n"

    source_image_format=$(get_source_image_format "$1")
    format_flag=$(set_format_flag "$source_image_format")
    args+=("$format_flag")

    start_time=$(date +%s)
    echo -e "qemu-img convert -p -t none ${args[@]}"
    end_time=$(date +%s)

    # Calculate conversion time in seconds
    conversion_time=$(($end_time - $start_time))

    # Calculate the size of the source image in bytes
    source_image_size=$(qemu-img info "$1" | grep -oP '(?<=virtual size: )\d+')
    source_image_size_bytes=$(echo "$source_image_size" | awk '{print $1 * 1024 * 1024 * 1024}')

    # Calculate the conversion rate in GB/s
    conversion_rate=$(echo "scale=2; $source_image_size_bytes / $conversion_time / 1024 / 1024 / 1024" | bc)

    echo -e "${color_green}\nImage conversion completed in $conversion_time seconds.${color_end}\n"
    echo -e "${color_orange}\nConversion rate: $conversion_rate GB/s.${color_end}\n"
}

# Check if any arguments are provided
if [ $# -gt 0 ]; then
    convert_image "$@"
else
    echo -e "${color_red}\nUsage: $0 [qemu-img convert options]${color_end}\n"
    exit 1
fi