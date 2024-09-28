# kelvim
A set of tools to manage snapshots and backups of KVM virtual machines

# Errors:

```
Failed to start backup: [internal error: unable to execute QEMU command 'nbd-server-start': Faile) to unlink socket /var/tmp/virtnbdbackup.1: Operation not permitted]
```

just perform:

```
sudo rm -rf /var/tmp/virtnbdbackup.1
```

In case of:

```
[2024-09-28 13:22:45] ERROR root job - start [main]: Failed to start backup: [internal error: unable to execute QEMU command 'transaction': Bitmap already exists: virtnbdbackup.0]
```

Just use:

```
sudo qemu-img bitmap --remove /elemento-vault-hdd/vid.334ac893d0824efaaee8baef379d41b5.elimg/data.img virtnbdbackup.0
```
