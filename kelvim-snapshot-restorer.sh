#!/bin/bash

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -s|--source)
            backup_source="$2"
            shift 2
            ;;
        -t|--target)
            backup_target="$2"
            shift 2
            ;;
        -b|--blockdev)
            input_blockdev="$2"
            shift 2
            ;;
        -u|--until)
            until="$2"
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
if [ -z $backup_target ]; then
    backup_target="$backup_source/restored"
fi
container_image="ghcr.io/abbbi/virtnbdbackup:master"
restore_command="virtnbdrestore --raw -i /tmp/source -o /tmp/target -c --until $until"

# Print starting message
echo -e "${color_purple}\nStarting Elemento Kelvim Restore utility ($(date +"%Y-%m-%d %H:%M:%S"))${color_end}"

echo -e "${color_orange}Backup directory source set at: $backup_source${color_end}"
echo -e "${color_orange}Restored image and files set at: $backup_target${color_end}"

# Run the podman command
sudo podman run -it \
    --privileged \
    -v /run:/run \
    -v /var/tmp:/var/tmp \
    -v "$backup_source:/tmp/source:ro" \
    -v "$backup_target:/tmp/target" \
    "$container_image" \
    $restore_command

# Print completion message
if [ $? -eq 0 ]; then
    echo -e "${color_green}\nBackup restore completed successfully.${color_end}"
    echo -e "${color_yellow}\nRestored image and files can be found at: $backup_target${color_end}"
else
    echo -e "${color_red}\nBackup restore failed.${color_end}"
fi