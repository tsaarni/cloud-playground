

kind create cluster --name permissions
kind delete cluster --name permissions

docker build --tag myalpine:latest docker/myalpine/
kind load docker-image myalpine:latest --name permissions

kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/shell-nonroot.yaml
kubectl exec shell-nonroot -- id

kubectl logs -f shell-nonroot


while true; do kubectl create secret generic mysecret --from-file=password=/proc/sys/kernel/random/uuid --dry-run=client -o yaml | kubectl apply -f -; sleep 1; done
