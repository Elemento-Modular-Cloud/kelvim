#! /bin/bash

# Regex patterns
elimg_pattern=".*/[^/]+\.elimg(/|$)"
img_pattern="^\/tmp\/elemento\/exported\/data_[0-9a-fA-F\-]+\.img$"

# Colors
color_blue='\033[94m'
color_red='\033[91m'
color_orange='\033[93m'
color_purple='\033[95m'
color_green='\033[92m'
color_end='\033[0m'

# Load domain names into an array
readarray -t domain_array < <(sudo virsh list --all | awk 'NR>2 && $2 != "" {print $2}')

# Date string used to create the right folder
date_string=$(date +"%y%m%d")

# External backup media
ext_backup_media="/mnt/elemento-vault/snaps"

# Container URI
cont_uri="ghcr.io/abbbi/virtnbdbackup:master"
podman_base_call="podman run -d --privileged --rm -v /run:/run -v /var/tmp:/var/tmp -v /mnt/backups:/mnt/backups"

# Iterate over the array
for domain in "${domain_array[@]}"; do
    echo -e "${color_orange}Processing domain: $domain $color_end"
    
    # Get block devices and load into an array
    readarray -t blk_array < <(sudo virsh domblklist "$domain" | awk 'NR>2 && $1 != "" {print $1 " " $2}')

    # Get the <loader> element from the VM's XML configuration
    xml_dump=$(sudo virsh dumpxml "$domain")
    loader_info=$(echo $xml_dump | grep -i "<loader ")

    fw_info="unknown"
    # Determine the firmware mode
    if [[ -z "$loader_info" ]]; then
    echo "Firmware mode: BIOS"
    fw_info="bios"
    elif (echo "$loader_info" | grep -qi "pflash") || (echo "$xml_dump" | grep -qi | grep "firmware=[\",\']efi[\",\']"); then
    echo "Firmware mode: UEFI"
    fw_info="uefi"
    else
    echo "Firmware mode: Unknown (potentially BIOS with ROM)"
    fw_info="unknown"
    fi
    
    # Iterate over the block devices array and print the name and source
    for blk in "${blk_array[@]}"; do
        # Split each line into target and source
        target=$(echo $blk | awk '{print $1}')
        source=$(echo $blk | awk '{print $2}')
        echo -e "$color_blue\tBlock device target: $target, source: $source $color_end"
        
        # Get img format
        format=$(qemu-img info -U "$source" | grep -oP '(?<=file format: ).*')

        # Check if the source contains a folder ending with ".elimg"
        if [[ "$source" =~ $elimg_pattern ]]; then
            elimg_path=$(echo "$source" | sed -E 's|(/[^/]*\.elimg)/.*|\1|')
            target_dir="$elimg_path/snaps/$date_string"
            
            echo -e "$color_blue\tSource is placed in a '.elimg'. Creating snapshots alongside.$color_end"

        elif [[ "$source" =~ $img_pattern ]]; then
            uuid=$(echo "$source" | awk -F'/' '{print $NF}' | awk -F'.img' '{print $1}')
            target_dir="$ext_backup_media/$uuid.elsnaps/$date_string"
            
            echo -e "$color_blue\tSource locally mounted via storageserver export. Creating snapshots on external backup media $ext_backup_media.$color_end"

        else
            echo -e "$color_red\t\tCannot handle this volume since it's not Elemento-based$color_end"
            continue
        fi

        echo -e "$color_purple\t\tFormat is $format.$color_end"
        echo -e "$color_purple\t\tFirmware is $fw_info.$color_end"

        if [[ "$format" == "raw" ]]; then
            if [[ -e "$target_dir/$target.copy.data" ]]; then
                echo -e "$color_purple\t\tDisk format is RAW and full backup is already present. Skipping.$color_end"
                # continue
            fi
        fi

        volumes="-v $target_dir:/target:z -v $source:$source"

        if [[ "$fw_info" == "uefi" ]]; then
            echo -e "$color_purple\t\tBacking up TPM files.$color_end"
            sudo mkdir -p $target_dir/tpm
            sudo cp -r /var/lib/libvirt/swtpm/$domain $target_dir/tpm
            
            # Extract the loader path
            loader_path=$(echo "$xml_dump" | sed -n "s/.*<loader[^>]*>\(.*\)<\/loader>.*/\1/p")
            if [ $loader_path ]; then
                volumes="$volumes -v $loader_path:$loader_path"
            fi

            # Extract the nvram path
            nvram_path=$(echo "$xml_dump" | sed -n "s/.*<nvram[^>]*>\(.*\)<\/nvram>.*/\1/p")
            if [ $nvram_path ]; then
                volumes="$volumes -v $nvram_path:$nvram_path"
            fi
        fi

        echo -e "\tStarting backup of disk $uuid towards $target_dir..."
        sudo mkdir -p $target_dir
        cont_name="elsnap.$domain.$target"
        sudo $podman_base_call $volumes --name $cont_name $cont_uri virtnbdbackup --raw -d $domain -i $target -l auto -o /target
        
        echo -e "${color_green}Container running on podman with name $cont_name$color_end"
    done
done
