
# Testing service account token expiration

Start a new cluster with a configuration file that enables service account expiration.

```console
kind delete cluster --name exptest
kind create cluster --config configs/kind-cluster-config.yaml --name exptest
```

Observe the default service account expiration time.
The minimum that Kubernetes allows is 1 hour, so it is bit tedious from the perspective of running tests.

```console
kubectl apply -f manifests/default.yaml
kubectl exec -it sa-defaults -- python3 -c "import jwt, time, sys; t = jwt.decode(open(sys.argv[1]).read(), verify=False); print('Expires in: {}\nTime now: {}'.format(time.ctime(t['exp']), time.ctime()))" /var/run/secrets/kubernetes.io/serviceaccount/token
```

Observe the expiration of "bound service account" tokens.
The minimum that Kubernetes allows is 10 minutes.

```console
kubectl apply -f manifests/sa-with-audience-and-expiration.yaml
kubectl exec -it audience -- python3 -c "import jwt, time, sys; t = jwt.decode(open(sys.argv[1]).read(), verify=False); print('Expires in: {}\nTime now: {}'.format(time.ctime(t['exp']), time.ctime()))" /projected/token
```

To make manual API server requests run

```console
kubectl exec -it audience -- ash
http --verify=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST/api/v1/namespaces/default/pods Authorization:"Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
http --verify=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST/api/v1/namespaces/default/pods Authorization:"Bearer $(cat /projected/token)"
```
