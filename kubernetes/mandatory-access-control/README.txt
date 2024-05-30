


# on host, check that apparmor is enabled
aa-enabled      # check if apparmor is enabled on host, should print "Yes"
sudo aa-status  # check processes with apparmor profiles

# create a cluster
kind delete cluster --name mac-test   # delete old if exists
kind create cluster --name mac-test


#
# Preparations to make apparmor available in the kind node
#

# exec into the kind node
docker exec -it mac-test-control-plane bash

# inside the container run following
mount -t securityfs securityfs /sys/kernel/security  # to make apparmor available in the container
apt update && apt install apparmor                   # install apparmor_parser

# restart containerd and kubelet for the changes to take effect
systemctl restart containerd
systemctl restart kubelet




#
# Test apparmor
#

## restricted
kubectl apply -f manifest/shell-restricted.yaml

kubectl exec shell-restricted -- cat /proc/1/attr/current
# output:
# cri-containerd.apparmor.d (enforce)

kubectl exec shell-restricted -- grep Seccomp /proc/1/status
# output:
# Seccomp:        2
# Seccomp_filters:        1


## default
kubectl apply -f manifest/shell-default.yaml

kubectl exec shell-default -- cat /proc/1/attr/current
# output:
# cri-containerd.apparmor.d (enforce)

kubectl exec shell-default -- grep Seccomp /proc/1/status
# output:
# Seccomp:        0
# Seccomp_filters:        0

## unconfined
kubectl apply -f manifest/shell-unconfined.yaml

kubectl exec shell-unconfined -- cat /proc/1/attr/current
# output:
# unconfined (enforce)

kubectl exec shell-unconfined -- grep Seccomp /proc/1/status
# output:
# Seccomp:        0
# Seccomp_filters:        0



## Create a namespace with restricted pod security policy

kubectl create ns restricted
kubectl label --overwrite ns restricted  \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest


kubectl -n restricted apply -f manifest/shell-restricted.yaml  # this should succeed
kubectl -n restricted apply -f manifest/shell-default.yaml  # this should fail
kubectl -n restricted apply -f manifest/shell-unconfined.yaml  # this should fail




### SELinux  (TODO)

# selinux on host
getenforce
# Enforcing



cat /proc/1/attr/current






#### Checks in container runtime if AppArmor enabled

https://github.com/opencontainers/runc/blob/1aeefd9cbdda983d75bdd8d869fe2ac5faab3707/libcontainer/apparmor/apparmor_linux.go#L18-L26

https://github.com/containerd/containerd/blob/eb8b3de9d3f8b137efe26d62e5df274a00adf51a/pkg/apparmor/apparmor_linux.go#L34-L44
