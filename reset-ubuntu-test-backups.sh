#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (sudo). Please run with sudo."
    exit 1
fi

original_disk_image_path="/elemento-vault-hdd/vid.334ac893d0824efaaee8baef379d41b5.elimg/data.img"

# Function to shutdown the ubuntu-test VM
shutdown_ubuntu_test() {
    echo "Shutting down ubuntu-test VM..."
    virsh shutdown ubuntu-test
    
    # Wait for the VM to shut down (timeout after 60 seconds)
    timeout=60
    while virsh list --all | grep -q "ubuntu-test.*running" && [ $timeout -gt 0 ]; do
        sleep 1
        ((timeout--))
    done

    if [ $timeout -eq 0 ]; then
        echo "Warning: ubuntu-test VM did not shut down gracefully. Forcing power off..."
        virsh destroy ubuntu-test
    else
        echo "ubuntu-test VM has been shut down successfully."
    fi
}

# Function to start the ubuntu-test VM
start_ubuntu_test() {
    echo "Starting ubuntu-test VM..."
    virsh start ubuntu-test
    
    # Wait for the VM to start (timeout after 60 seconds)
    timeout=60
    while ! virsh list --all | grep -q "ubuntu-test.*running" && [ $timeout -gt 0 ]; do
        sleep 1
        ((timeout--))
    done

    if [ $timeout -eq 0 ]; then
        echo "Error: ubuntu-test VM failed to start within the timeout period."
        return 1
    else
        echo "ubuntu-test VM has been started successfully."
    fi
}

# Function to restart the ubuntu-test VM
restart_ubuntu_test() {
    echo "Restarting ubuntu-test VM..."
    shutdown_ubuntu_test
    if start_ubuntu_test; then
        echo "ubuntu-test VM has been restarted successfully."
    else
        echo "Error: Failed to restart ubuntu-test VM."
        return 1
    fi
}

# Function to get the source file for vda disk
get_vda_source() {
    local vda_source=$(virsh domblklist ubuntu-test | grep vda | awk '{print $2}')

    if [ -z "$vda_source" ]; then
        echo "Error: Unable to find the source file for vda disk of ubuntu-test VM." >&2
        return 1
    else
        echo "vda source is currently: $vda_source"
        return 0
    fi
}

# Function to get bitmap names from qemu-img info output
get_bitmap_names() {
    local image_path="$1"
    local bitmap_names=$(qemu-img info "$image_path" | awk '/name: virtnbdbackup/ {print $2}')
    echo "Found bitmaps:"
    if [ -z "$bitmap_names" ]; then
        echo "No bitmaps found for $image_path" >&2
        return 1
    else
        echo -e "\t$bitmap_names"
        return 0
    fi
}

# Function to process bitmaps
clean_bitmaps() {
    local vda_source="$1"
    local bitmap_names="$2"

    if [ -n "$bitmap_names" ]; then
        echo "Processing bitmaps:"
        while IFS= read -r bitmap; do
            if [ -z "$bitmap" ]; then
                continue
            fi
            echo -e "\tRemoving $bitmap metadata"
            sudo qemu-img bitmap --remove $original_disk_image_path $bitmap
        done <<< "$bitmap_names"
    else
        echo "No bitmaps to process."
    fi
}

# Function to check and update vda source if necessary
check_and_update_vda_source() {
    local expected_vda_source=$original_disk_image_path

    echo "Updating VM configuration to use $expected_vda_source as vda source..."
    sed "s|<source file='.*'/>|<source file='$expected_vda_source'/>|" <(virsh dumpxml ubuntu-test) | virsh define /dev/stdin

    if [ $? -eq 0 ]; then
        echo "VM configuration updated successfully."
    else
        echo "Error: Failed to update VM configuration." >&2
        return 1
    fi
}


# Call the function to shutdown ubuntu-test VM
shutdown_ubuntu_test
# Get vda source
vda_source=$(get_vda_source)
# Check and update vda source if necessary
check_and_update_vda_source "$vda_source"
# Get bitmap names for the vda disk
bitmap_names=$(get_bitmap_names "$original_disk_image_path")
# Call the function to clean bitmaps
clean_bitmaps "$original_disk_image_path" "$bitmap_names"
# Remove the restored directory and the snapshot directory
rm -rf /tmp/restored/*
rm -rf /mnt/elemento-vault/snaps/334ac893d0824efaaee8baef379d41b5.elsnaps/*
# Run kelvim-snapshot-sanitizer.sh with the -d option to delete snapshots
/opt/kelvim/kelvim-snapshot-sanitizer.sh -d ubuntu-test
# Restart the ubuntu-test VM
start_ubuntu_test
