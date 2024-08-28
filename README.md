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