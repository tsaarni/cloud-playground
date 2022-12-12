
# Create cluster
kind create cluster --name permissions
kind delete cluster --name permissions


# Test by using shell script

docker build --tag myalpine:latest docker/myalpine/
kind load docker-image myalpine:latest --name permissions

kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/shell-nonroot.yaml
kubectl logs -f shell-nonroot

while true; do kubectl create secret generic mysecret --from-file=password=/proc/sys/kernel/random/uuid --dry-run=client -o yaml | kubectl apply -f -; sleep 1; done


# Test by using go application

docker build --tag dirwatcher:latest docker/dirwatcher/
kind load docker-image dirwatcher:latest --name permissions

kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/dirwatcher-nonroot.yaml
kubectl logs -f dirwatcher-nonroot

while true; do kubectl create secret generic mysecret --from-file=password=/proc/sys/kernel/random/uuid --dry-run=client -o yaml | kubectl apply -f -; sleep 1; done



# Enable verbose logs for kubelet

change /var/lib/kubelet/config.yaml to:

logging:
  verbosity: 4


kill $(pidof kubelet)
journalctl -u kubelet -f



Dec 12 16:18:26 permissions-control-plane kubelet[10646]: I1212 16:18:26.493642   10646 volume_linux.go:111] "Perform recursive ownership change for directory" path="/var/lib/kubelet/pods/e396daba-aa5b-4315-9595-783bb69dbe7d/volumes/kubernetes.io~secret/mysecret"



# Links to relevant code

https://github.com/kubernetes/kubernetes/blob/master/pkg/volume/volume_linux.go
https://github.com/kubernetes/kubernetes/blob/master/pkg/volume/util/atomic_writer.go
