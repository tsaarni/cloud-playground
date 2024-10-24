

# Preconditions: check that apparmor is enabled on host
aa-enabled      # should print "Yes"


# create a cluster
kind delete cluster --name mac-test   # delete old if exists
kind create cluster --name mac-test


#
# Preparations to make apparmor available in the kind node
#

# exec into the kind node
docker exec -it mac-test-control-plane bash

# inside "mac-test-control-plane" container run following
mount -t securityfs securityfs /sys/kernel/security  # to make apparmor available in the container
apt update && apt install apparmor                   # install apparmor_parser

# restart containerd and kubelet for the changes to take effect
systemctl restart containerd
systemctl restart kubelet




#
# Test apparmor
#

## restricted
kubectl apply -f manifest/restricted.yaml

kubectl exec restricted -- cat /proc/1/attr/current
# output:
# cri-containerd.apparmor.d (enforce)

kubectl exec restricted -- grep Seccomp /proc/1/status
# output:
# Seccomp:        2
# Seccomp_filters:        1


## default
kubectl apply -f manifest/default.yaml

kubectl exec default -- cat /proc/1/attr/current
# output:
# cri-containerd.apparmor.d (enforce)

kubectl exec default -- grep Seccomp /proc/1/status
# output:
# Seccomp:        0
# Seccomp_filters:        0

## unconfined
kubectl apply -f manifest/unconfined.yaml

kubectl exec unconfined -- cat /proc/1/attr/current
# output:
# unconfined

kubectl exec unconfined -- grep Seccomp /proc/1/status
# output:
# Seccomp:        0
# Seccomp_filters:        0


## set pod level profile to define the default for all containers in the pod
## and override it for one container

kubectl apply -f manifest/pod-level-security-context.yaml

kubectl exec pod-level-security-context -c default-unconfined -- cat /proc/1/attr/current
# output:
# unconfined

kubectl exec pod-level-security-context -c override-pod-level-default -- cat /proc/1/attr/current
# output:
# cri-containerd.apparmor.d (enforce)



### AppArmor custom profile

# load custom profile on host
sudo apparmor_parser -r configs/apparmor-deny-test

# check that it was loaded
sudo apparmor_status | grep apparmor-deny-test


kubectl apply -f manifest/custom.yaml

kubectl exec custom -- touch /tmp/denied
# output:
# touch: /tmp/denied: Permission denied
# command terminated with exit code 1

kubectl exec custom -- touch /tmp/not-denied



## Mixed case: using annotation and security context within single pod

kubectl apply -f manifest/mixing-annotations-and-security-context.yaml
# output:
# Warning: metadata.annotations[container.apparmor.security.beta.kubernetes.io/annotation]: deprecated since v1.30; use the "appArmorProfile" field instead
kubectl exec mixing-annotations-and-security-context -c securitycontext -- cat /proc/1/attr/current
# output:
# unconfined
kubectl exec mixing-annotations-and-security-context -c annotation -- cat /proc/1/attr/current
# output:
# unconfined




## Failing validation

### https://github.com/kubernetes/kubernetes/issues/128306


kubectl apply -f manifest/deployment-fails-validation.yaml
# output:
# The Deployment "deployment-fails-validation" is invalid: spec.template.spec.containers[0].securityContext.appArmorProfile.type: Forbidden: apparmor type in annotation and field must match



### pod security standard


## Create a namespace that enforces restricted pod security standard

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
# output:
# Enforcing


cat /proc/1/attr/current






#### Notes
# Checks in container runtime code for AppArmor being enabled

https://github.com/opencontainers/runc/blob/1aeefd9cbdda983d75bdd8d869fe2ac5faab3707/libcontainer/apparmor/apparmor_linux.go#L18-L26

https://github.com/containerd/containerd/blob/eb8b3de9d3f8b137efe26d62e5df274a00adf51a/pkg/apparmor/apparmor_linux.go#L34-L44


# default container runtime profile
https://github.com/containerd/containerd/blob/eb8b3de9d3f8b137efe26d62e5df274a00adf51a/contrib/apparmor/template.go#L42-L95
