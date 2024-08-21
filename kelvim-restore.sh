#!/bin/bash

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--domain)
            input_domain="$2"
            shift 2
            ;;
        -b|--blockdev)
            input_blockdev="$2"
            shift 2
            ;;
        -f|--from)
            input_date="$2"
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
backup_source="/mnt/elemento-vault/vid.$input_domain.elimg/snaps/$input_date"
backup_target="/tmp/target"
container_image="ghcr.io/abbbi/virtnbdbackup:master"
restore_command="virtnbdrestore --raw -i $backup_target -o /tmp/restore -c"

# Print starting message
echo -e "${color_purple}\nStarting backup restore utility ($(date +"%Y-%m-%d %H:%M:%S"))${color_end}"

# Run the podman command
sudo podman run -it \
    --privileged \
    -v /run:/run \
    -v /var/tmp:/var/tmp \
    -v /mnt/backups:/mnt/backups \
    -v "$backup_source:$backup_target:z" \
    "$container_image" \
    $restore_command

# Print completion message
if [ $? -eq 0 ]; then
    echo -e "${color_green}\nBackup restore completed successfully.${color_end}"
else
    echo -e "${color_red}\nBackup restore failed.${color_end}"
fi