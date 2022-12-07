
kind delete cluster --name mac-test
kind create cluster --config configs/kind-cluster-config.yaml --name mac-test


mount -t securityfs securityfs /sys/kernel/security



# apparmor on host
aa-enabled 
# Yes

sudo aa-status 

kubectl label --overwrite ns default  \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest 


kubectl apply -f manifest/shell-nonroot.yaml
kubectl exec shell -- cat /proc/1/attr/current
kubectl delete pod shell --force



# selinux on host
getenforce
# Enforcing



# security attributes for the process (apparmor & selinux)
cat /proc/1/attr/current

# seccomp
grep Seccomp /proc/1/status
# Seccomp:        2
# unconfined:  Seccomp:        0


