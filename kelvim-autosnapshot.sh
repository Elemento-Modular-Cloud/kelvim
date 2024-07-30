#! /bin/bash

# Regex patterns
elimg_pattern=".*/[^/]+\.elimg(/|$)"
img_pattern="^/tmp/elemento/exported/[0-9a-fA-F\-]{36}\.img$"

# Colors
color_blue='\033[94m'
color_red='\033[91m'
color_orange='\033[93m'
color_end='\033[0m'

# Load domain names into an array
readarray -t domain_array < <(sudo virsh list --all | awk 'NR>2 && $2 != "" {print $2}')

# Date string used to create the right folder
date_string=$(date +"%y%m%d")

# External backup media
ext_backup_media="/mnt/elemento-vault/snaps"

# Dry run flag
DRY_RUN=true

# Wrapper function to execute commands or echo based on DRY_RUN flag
run_or_echo() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "$@"
    else
        if ! sudo -n true 2>/dev/null; then
            echo "Please enter your sudo password to continue:"
            sudo "$@"
        else
            sudo "$@"
        fi
    fi
}

# Iterate over the array
for domain in "${domain_array[@]}"; do
    echo -e "$color_orange Processing domain: $domain $color_end"
    
    # Get block devices and load into an array
    readarray -t blk_array < <(sudo virsh domblklist "$domain" | awk 'NR>2 && $1 != "" {print $1 " " $2}')
    
    # Iterate over the block devices array and print the name and source
    for blk in "${blk_array[@]}"; do
        # Split each line into target and source
        target=$(echo $blk | awk '{print $1}')
        source=$(echo $blk | awk '{print $2}')
        echo -e "$color_blue\tBlock device target: $target, source: $source $color_end"

        # Check if the source contains a folder ending with ".elimg"
        if [[ "$source" =~ $elimg_pattern ]]; then
            echo -e "$color_blue\tSource is placed in a '.elimg'. Creating snapshots alongside. $color_end"
            elimg_path=$(echo "$source" | sed -E 's|(/[^/]*\.elimg)/.*|\1|')
            echo -e "\tStarting backup of disk $uuid towards $elimg_path/snaps/$date_string..."
            if $DRY_RUN; then
                echo -e "\tWARNING: Dry run! Not actually performing operations"
            fi
            run_or_echo "\t\tmkdir -p $elimg_path/snaps/$date_string"
            run_or_echo "\t\tvirtnbdbackup -d $domain -i $target -l auto -o $elimg_path/snaps/$date_string"
            echo -e "\tDONE!"
        elif [[ "$source" =~ $img_pattern ]]; then
            echo -e "$color_blue\tSource locally mounted via storageserver export. Creating snapshots on external backup media $ext_backup_media. $color_end"
            uuid=$(echo "$source" | awk -F'/' '{print $NF}' | awk -F'.img' '{print $1}')
            echo -e "\tStarting backup of disk $uuid towards $ext_backup_media/$uuid.elsnaps/$date_string..."
            if $DRY_RUN; then
                echo -e "\tWARNING: Dry run! Not actually performing operations"
            fi
            run_or_echo "\t\tmkdir -p $ext_backup_media/$uuid.elsnaps/$date_string"
            run_or_echo "\t\tvirtnbdbackup -d $domain -i $target -l auto -o $ext_backup_media/$uuid.elsnaps/$date_string"
            echo -e "\tDONE!"
        else
            echo -e "$color_red\t\tCannot handle this volume since it's not Elemento-based$color_end"
        fi
    done
done
