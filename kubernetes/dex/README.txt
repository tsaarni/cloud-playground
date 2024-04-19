


# create certs

rm -rf certs
mkdir -p certs
certyaml -d certs configs/certs.yaml


# create a kind cluster

kind delete cluster --name dex
kind create cluster --config configs/kind-cluster-config.yaml --name dex


# deploy contour

kubectl apply -f https://projectcontour.io/quickstart/contour.yaml



kubectl create secret tls dex-cert --cert=certs/dex.pem --key=certs/dex-key.pem --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls openldap-cert --cert=certs/ldap.pem --key=certs/ldap-key.pem --dry-run=client -o yaml | kubectl apply -f -


# build and deploy openldap

docker build docker/openldap/ -t localhost/openldap:latest
kind load docker-image --name dex localhost/openldap:latest
kubectl create configmap openldap-config --dry-run=client -o yaml --from-file=templates/database.ldif --from-file=templates/users-and-groups.ldif | kubectl apply -f -
kubectl apply -f manifests/openldap.yaml





# https://github.com/dexidp/dex
# https://dexidp.io/docs/

kubectl apply -f manifests/dex.yaml

kubectl apply -f manifests/rbac.yaml


https://dex.127.0.0.152.nip.io/.well-known/openid-configuration

http --verify certs/ca.pem https://dex.127.0.0.152.nip.io/.well-known/openid-configuration


# https://github.com/int128/kubelogin



# Install krew plugin manager
#
# https://krew.sigs.k8s.io/plugins/
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/

curl -L https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz -o krew.tar.gz
mkdir -p krew-install
tar zxvf krew.tar.gz -C krew-install
./krew-install/krew-linux_amd64 install krew
rm -rf krew-install krew.tar.gz

export PATH="$HOME/.krew/bin:$PATH"

# install oidc-login (kubelogin) via krew plugin manager
#
# https://github.com/int128/kubelogin

kubectl krew install oidc-login


kubectl config set-credentials oidc \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=https://dex.127.0.0.152.nip.io \
  --exec-arg=--oidc-client-id=kubernetes \
  --exec-arg=--oidc-client-secret=myclientsecret \
  --exec-arg=--oidc-extra-scope=email \
  --exec-arg=--oidc-extra-scope=groups \
  --exec-arg=--certificate-authority=certs/ca.pem

kubectl --user=oidc get secrets

rm -rf ~/.kube/cache/oidc-login

apps/jwt-decode.py



sudo nsenter --target $(pgrep slapd) --net wireshark -f  "port 389" -k -Y ldap



kubectl logs deployments/dex -f


# test memberof
kubectl exec $(kubectl get pods -l app=openldap -o jsonpath='{.items[0].metadata.name}') -- ldapsearch -D "cn=ldap-admin,ou=users,o=example" -w ldap-admin -LLL -b ou=users,o=example -s sub memberOf

kubectl exec -it shell ash

KUBECONFIG=/host/etc/kubernetes/admin.conf kubectl get pod

cat > cluster-admin.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jill-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: User
  name: jill@example.com
  apiGroup: rbac.authorization.k8s.io
EOF

KUBECONFIG=/host/etc/kubernetes/admin.conf kubectl apply -f cluster-admin.yaml
