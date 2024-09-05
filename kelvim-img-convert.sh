#!/bin/bash

# Colors
color_blue='\033[94m'
color_red='\033[91m'
color_orange='\033[93m'
color_purple='\033[95m'
color_green='\033[92m'
color_end='\033[0m'

# Function to get the format of the source image
get_source_image_format() {
    local source_image="$1"
    local source_image_format=$(qemu-img info "$source_image" | grep -oP '(?<=file format: ).*')
    echo "$source_image_format"
}

# Function to set the format flag for the source image
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

# Function to set the output format flag
set_output_format_flag() {
    local output_image_format="$1"
    case "$output_image_format" in
        "raw")
            echo "-O raw"
            ;;
        "qcow2")
            echo "-O qcow2"
            ;;
        "vmdk")
            echo "-O vmdk"
            ;;
        *)
            echo -e "${color_red}\nUnsupported output image format: $output_image_format${color_end}\n"
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

    # Extract source and target images from the arguments
    source_image="${args[-2]}"
    target_image="${args[-1]}"
    args=("${args[@]:1:${#args[@]}-3}") # Remove source and target images from the arguments

    source_image_format=$(get_source_image_format "$source_image")
    output_format_flag=$(set_output_format_flag "${args[0]}")
    args=("${args[@]:1}") # Remove output format from the arguments

    # Display information about formats and image paths before starting conversion
    echo -e "${color_blue}\nSource Image: $source_image\nSource Format: $source_image_format\nTarget Image: $target_image\nOutput Format: ${args[0]}${color_end}\n"

    format_flag=$(set_format_flag "$source_image_format")
    args+=("$format_flag" "$output_format_flag" "$source_image" "$target_image")

    start_time=$(date +%s)
    sudo qemu-img convert -p -t none ${args[@]}
    end_time=$(date +%s)

    # Calculate conversion time in seconds
    conversion_time=$(($end_time - $start_time))

    # Calculate the size of the source image in bytes
    source_image_size=$(qemu-img info "$source_image" | grep -oP '(?<=virtual size: )\d+')
    source_image_size_bytes=$(echo "$source_image_size" | awk '{print $1 * 1024 * 1024 * 1024}')

    # Calculate the conversion rate in GB/s
    conversion_rate=$(echo "scale=2; $source_image_size_bytes / $conversion_time / 1024 / 1024 / 1024" | bc)

    echo -e "${color_green}\nImage conversion completed in $conversion_time seconds.${color_end}\n"
    hourly_conversion_rate=$(echo "scale=2; $conversion_rate * 3600" | bc)
    echo -e "${color_orange}\nConversion rate: $conversion_rate GB/s ($hourly_conversion_rate GB/h).${color_end}\n"
}

# Check if any arguments are provided
if [ $# -gt 2 ]; then
    convert_image "$@"
else
    echo -e "${color_red}\nUsage: $0 [output format] [qemu-img convert options] source_image target_image${color_end}\n"
    exit 1
fi