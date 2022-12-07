
```console
mkdir -p certs
certyaml -d certs


podman build -t openldap:latest docker/openldap/
podman build -t sshd:latest docker/ldap-client/

 
podman network create test

podman run \
  --name openldap \
  --volume $PWD:/input:ro \
  --env CERT_FILENAME=/input/certs/server.pem \
  --env KEY_FILENAME=/input/certs/server-key.pem \
  --env CA_FILENAME=/input/certs/ca.pem \
  --network test \
  openldap:latest

podman run --name sshd --volume $PWD:/input:ro --publish 2222:22 --network test sshd:latest


sshpass -p user ssh user@localhost -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "echo Hello world!"


podman stop openldap
podman rm openldap
podman stop sshd
podman rm sshd

podman network rm test

```







```console

# capabilities
grep Cap /proc/1/status
capsh --decode=


# user namespace
readlink /proc/1/ns/user

# security attributes for the process (apparmor & selinux)
cat /proc/1/attr/current

# seccomp
grep Seccomp /proc/1/status
# Seccomp:        2
# unconfined:  Seccomp:        0
```
