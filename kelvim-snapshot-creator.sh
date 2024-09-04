#! /bin/bash

# Initialize variables
input_domain=""

# By default containers will be run in detached mode
interactive="-d"

# Parse arguments
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
        -i|--interactive)
            interactive="-it"
            shift 1
            ;;
        -e|--external)
            external=true
            shift 1
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo $input_domain
echo $input_blockdev

# Check if domain is set
if [ -z "$input_domain" ]; then
    # Load domain names into an array
    readarray -t domain_array < <(sudo virsh list --all | awk 'NR>2 && $2 != "" {print $2}')
else
    domain_array="$input_domain"
fi

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

# Date string used to create the right folder
date_string=$(date +"%y%m%d")

# External backup media
ext_backup_media="/mnt/elemento-vault/snaps"

# Container URI
cont_uri="ghcr.io/abbbi/virtnbdbackup:latest"
podman_base_call="podman run --privileged --rm $interactive -v /run:/run -v /var/tmp:/var/tmp"

echo -e "${color_purple}\nStarting Elemento Kelvim Backup utility ($(date +"%Y-%m-%d %H:%M:%S"))${color_end}"

if [[ "$external" == true ]]; then
    echo -e "${color_green}\nRunning in forced external mode. Target directory set to $ext_backup_media\n$color_end"
fi

# Iterate over the array
for domain in "${domain_array[@]}"; do
    domain_uuid=$(sudo virsh domuuid $domain)
    echo -e "${color_orange}\nProcessing domain: $domain($domain_uuid) $color_end"

    # 
    # echo -e "${color_green}\nCleaning previous checkpoints to avoid conflicts. $color_end"
    # checkpoints=($(sudo virsh checkpoint-list $domain | awk 'NR>2 {print $1}' | sort -t '.' -k 2,2n))
    # for checkpoint in "${checkpoints[@]}"; do
    #     sudo virsh checkpoint-delete $domain --metadata $checkpoint
    # done

    # Get block devices and load into an array
    readarray -t blk_array < <(sudo virsh domblklist "$domain" | awk 'NR>2 && $1 != "" {print $1 " " $2}')

    # Get the <loader> element from the VM's XML configuration
    xml_dump=$(sudo virsh dumpxml "$domain")
    loader_info=$(echo $xml_dump | grep -i "<loader ")

    fw_info="unknown"
    # Determine the firmware mode
    if [[ -z "$loader_info" ]]; then
    fw_info="bios"
    elif (echo "$loader_info" | grep -qi "pflash") || (echo "$xml_dump" | grep -qi | grep "firmware=[\",\']efi[\",\']"); then
    fw_info="uefi"
    else
    fw_info="unknown"
    fi
    
    # Iterate over the block devices array and print the name and source
    for blk in "${blk_array[@]}"; do
        # Split each line into target and source
        target=$(echo $blk | awk '{print $1}')
        source=$(echo $blk | awk '{print $2}')
        
        if [ ! -z "$input_blockdev" ]; then
            # Check if domain is set
            if [ "$target" != "$input_blockdev" ]; then
                echo -e "$color_yellow\tBlock device $target $color_end"
                continue
            else
                echo -e "$color_blue\tBlock device target: $target, source: $source $color_end"
            fi
        fi

        
        # Get img format
        format=$(qemu-img info -U "$source" | grep -oP '(?<=file format: ).*')

        # Check if the source contains a folder ending with ".elimg"
        if [[ "$external" != true && "$source" =~ $elimg_pattern ]]; then
            elimg_path=$(echo "$source" | sed -E 's|(/[^/]*\.elimg)/.*|\1|')
            target_dir="$elimg_path/snaps/$date_string"
            
            echo -e "$color_blue\tSource is placed in a '.elimg'. Creating snapshots alongside.$color_end"

        else
            if [[ "$source" =~ $elimg_pattern ]]; then
                uuid=$(echo "$source" | awk -F'/' '{print $(NF-1)}' | awk -F'.' '{print $2}')
            else
                uuid=$(echo "$source" | awk -F'/' '{print $NF}' | awk -F'.img' '{print $1}')
            fi
            target_dir="$ext_backup_media/$uuid.elsnaps/$date_string"
            
            reason_string="Image is not in a .elimg path."
            if [[ "$external" == true ]]; then
                reason_string="External mode enforced."
            fi
            echo -e "$color_blue\t$reason_string Creating snapshots on external backup media $target_dir.$color_end"
        fi

        echo -e "$color_purple\t\tFormat is $format.$color_end"
        echo -e "$color_purple\t\tFirmware is $fw_info.$color_end"

        if [[ "$format" == "raw" ]]; then
            if [[ -e "$target_dir/$target.copy.data" ]]; then
                echo -e "$color_purple\t\tDisk format is RAW and full backup is already present. Skipping.$color_end"
                continue
            fi
        fi

        volumes="-v $target_dir:/target:z -v $source:$source"

        if [[ "$fw_info" == "uefi" ]]; then
            echo -e "$color_purple\t\tBacking up TPM files.$color_end"
            sudo mkdir -p $target_dir/tpm
            sudo cp -r /var/lib/libvirt/swtpm/$domain_uuid $target_dir/tpm
            
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

        echo -e "\tStarting backup of disk $uuid towards $target_dir"
        sudo mkdir -p $target_dir
        cont_name="elsnap.$domain.$target"
        cont_id=$(sudo $podman_base_call $volumes --name $cont_name $cont_uri virtnbdbackup --raw -d $domain -i $target -l auto -o /target)
        
        echo -e "${color_green}\tContainer running on podman with name $cont_name ($cont_id)$color_end"
    done
done
