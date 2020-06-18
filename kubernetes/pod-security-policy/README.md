
Start a new cluster

```bash
kind delete cluster --name psp-test
kind create cluster --config configs/kind-cluster-config.yaml --name psp-test

kubectl apply -f pod-security-policy.yaml
```

Create credentials for non-admin user

```bash
openssl req -new -newkey rsa:4096 -nodes -keyout joe-key.pem -out joe.csr -subj "/CN=joe"

cat <<EOF |
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: joe
spec:
  groups:
  - system:authenticated
  request: $(base64 -w0 joe.csr)
  usages:
  - client auth
EOF
envsubst | kubectl apply -f -

kubectl certificate approve joe
kubectl get csr joe -o jsonpath='{.status.certificate}' | base64 -d  > joe.pem
```

Create kube.config file for non-admin user

```bash
cp ~/.kube/config joe.config
kubectl config set-credentials joe --client-certificate=joe.pem --client-key=joe-key.pem --embed-certs --kubeconfig=joe.config
kubectl config set-context joe --cluster=$(kubectl config current-context) --namespace=joe --user=joe --kubeconfig=joe.config
kubectl config use-context joe --kubeconfig=joe.config
```


Crete namespace


```bash
kubectl create namespace joe
kubectl create rolebinding joe-admin --namespace=joe --clusterrole=admin --user=joe
```



```console
kubectl --kubeconfig=joe.config apply -f pod.yaml
Error from server (Forbidden): error when creating "pods.yaml": pods "privileged" is forbidden: unable to validate against any pod security policy: [spec.volumes[0]: Invalid value: "hostPath": hostPath volumes are not allowed to be used]
``` 


