#!/bin/sh -ex

# Note: ssh host key changes on every restart
# sshpass -p password ssh sshuser@localhost -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "echo Hello world!"
ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa
ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519

/usr/sbin/sshd -D
