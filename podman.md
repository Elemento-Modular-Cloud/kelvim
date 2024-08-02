podman run -it -v/run:/run -v/var/tmp:/var/tmp -v /mnt/backups:/mnt/backups ghcr.io/abbbi/virtnbdbackup:master virtnbdbackup -d fd630aa2-35fa-4cb1-a4f7-47282d97e412 -o /mnt/backups

# efi
podman run -it -v/run:/run -v/var/tmp:/var/tmp -v /mnt/elemento-vault/backups:/mnt/backups -v/usr/share/edk2:/usr/share/edk2 -v/var/lib/libvirt/qemu/nvram:/var/lib/libvirt/qemu/nvram ghcr.io/abbbi/virtnbdbackup:master virtnbdbackup -d 9f816c27-8aaf-456c-b982-61786855c74f  -o /mnt/backups --raw