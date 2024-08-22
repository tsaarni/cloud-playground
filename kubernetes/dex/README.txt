

## create certs

rm -rf certs
mkdir -p certs
certyaml -d certs configs/certs.yaml


## create a kind cluster

kind delete cluster --name dex
kind create cluster --config configs/kind-cluster-config.yaml --name dex


## upload certs

kubectl create secret tls dex-cert --cert=certs/dex.pem --key=certs/dex-key.pem --dry-run=client -o yaml | kubectl apply -f -

# append the CA cert to the dex-cert secret as ca.pem (for validating Keycloak's cert)
kubectl patch secret dex-cert -p '{"data":{"ca.pem":"'$(base64 -w0 certs/ca.pem)'"}}'

kubectl create secret tls openldap-cert --cert=certs/ldap.pem --key=certs/ldap-key.pem --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls keycloak-external --cert=certs/keycloak.pem --key=certs/keycloak-key.pem --dry-run=client -o yaml | kubectl apply -f -


## deploy contour

kubectl apply -f https://projectcontour.io/quickstart/contour.yaml


## build and deploy openldap

docker build docker/openldap/ -t localhost/openldap:latest
kind load docker-image --name dex localhost/openldap:latest
kubectl create configmap openldap-config --dry-run=client -o yaml --from-file=templates/database.ldif --from-file=templates/users-and-groups.ldif | kubectl apply -f -
kubectl apply -f manifests/openldap.yaml


## deploy postgres and keycloak

kubectl apply -f manifests/postgresql.yaml
kubectl apply -f manifests/keycloak.yaml


## Make external hosts resolvable from inside the cluster

ENVOY_CLUSTER_IP=$(kubectl -n projectcontour get service envoy -o jsonpath='{.spec.clusterIP}')
kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' > Corefile
sed -i 's/^}$//' Corefile   # remove trailing brace
cat >> Corefile <<EOF
    hosts /dev/null nip.io {
        $ENVOY_CLUSTER_IP keycloak.127.0.0.152.nip.io
        $ENVOY_CLUSTER_IP dex.127.0.0.152.nip.io
    }
}
EOF
kubectl -n kube-system create configmap coredns --from-file=Corefile --dry-run=client -o yaml | kubectl apply -f -
kubectl -n kube-system delete pod -l k8s-app=kube-dns  # restart coredns


## deploy dex
### https://github.com/dexidp/dex
### https://dexidp.io/docs/
kubectl apply -f manifests/dex.yaml


## deploy some example RBAC rules for testing users
kubectl apply -f manifests/rbac.yaml


## verify the setup
http --verify certs/ca.pem https://dex.127.0.0.152.nip.io/.well-known/openid-configuration
http --verify certs/ca.pem https://keycloak.127.0.0.152.nip.io/realms/master/.well-known/openid-configuration



## prepare to install kubelogin: krew plugin manager
### https://krew.sigs.k8s.io/plugins/
### https://krew.sigs.k8s.io/docs/user-guide/setup/install/

curl -L https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz -o krew.tar.gz
mkdir -p krew-install
tar zxvf krew.tar.gz -C krew-install
./krew-install/krew-linux_amd64 install krew
rm -rf krew-install krew.tar.gz

export PATH="$HOME/.krew/bin:$PATH"

## install oidc-login (kubelogin) via krew plugin manager
### https://github.com/int128/kubelogin

kubectl krew install oidc-login

kubectl krew update    # update plugin index
kubectl krew upgrade   # upgrade already installed plugins




### configure keycloak
### NOTE: Use incognito mode to avoid being logged in as "admin" in the browser when later running kubelogin
### https://keycloak.127.0.0.152.nip.io/
###  l: admin p: admin

1. Client Scopes

   Click "Create client scope"

      - Name: groups

   Click "Save"

   Select "Mappers" tab
   Click "Add predefined mapper"
   Search for "groups" and select it
   Click "Add"

2. Clients

   Click "Create client"

      General settings
        - Client ID: dex

      Capability config
        - Client authentication: on

      Login settings
        - Root URL: https://dex.127.0.0.152.nip.io
        - Valid Redirect URIs: https://dex.127.0.0.152.nip.io/callback

   Go to "Client Scopes" tab
   Click "Add client scope"
   Select "groups" and add as default

   Go to "Credentials" tab
   Copy the client secret and change it to the config.yaml file in the dex ConfigMap

NEW_CLIENT_SECRET=....
kubectl get configmap dex -o jsonpath='{.data.config\.yaml}' | sed "s/clientSecret: .*/clientSecret: $NEW_CLIENT_SECRET/" > config.yaml
kubectl create configmap dex --from-file=config.yaml --dry-run=client -o yaml | kubectl apply -f -
kubectl delete pod -l app=dex


4. Realm roles

   Click "Create realm"

      - Role Name: global-secret-reader

5. Users

   Click "Add user"

     - Username: jack
     - Email: jack@example.com
     - First name: Jackfirst
     - Last name: Jacklast

   Select "Email Verified"

   Click "create"

   Select "Credentials" tab
   Click "Set password"

     - Password: jack
     - Password confirmation: jack
     - Temporary: off

   Click "Save" and "Save Password"

   Select "Role Mappings" tab
   Click "Assign role"
   Select "global-secret-reader"


###############
#
# login
#


kubectl config set-credentials jill \
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

## jill is in group "namespace-default-admin"

kubectl --user=jill get secrets  # succeeds
kubectl --user=jill --namespace kube-system get secrets  # Forbidden

## joe is in group "global-secret-reader"

kubectl config set-credentials joe \
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

kubectl --user=joe get secrets  # succeeds
kubectl --user=joe --namespace kube-system get secrets  # succeeds
kubectl --user=joe get pods  # Forbidden


## jack is in group "global-secret-reader"

kubectl config set-credentials jack \
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


kubectl --user=jack get secrets  # succeeds
kubectl --user=jack --namespace kube-system get secrets  # succeeds

# decode the tokens currenly in kubeconfig
apps/jwt-decode.py



# cleanup to login again
rm -rf ~/.kube/cache/oidc-login ~/.kube/cache/http

kubectl config delete-user jill
kubectl config delete-user joe
kubectl config delete-user jack




###############
#
# policies
#


kubectl label namespaces default environment=unprivileged

kubectl apply -f manifests/policy.yaml




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


###############
#
# troubleshooting
#


## ldap troubleshooting

sudo nsenter --target $(pgrep slapd) --net wireshark -f "port 389" -k -Y ldap

# test memberof
kubectl exec $(kubectl get pods -l app=openldap -o jsonpath='{.items[0].metadata.name}') -- ldapsearch -D "cn=ldap-admin,ou=users,o=example" -w ldap-admin -LLL -b ou=users,o=example -s sub memberOf



## troubleshooting login errors

kubectl -n kube-system logs kube-apiserver-dex-control-plane
kubectl logs deployment/dex


## monitor oidc flow

sudo nsenter --target $(pidof envoy) --net wireshark -k -Y 'http && http.request.uri.path!="/ready"'


## dump dex database

sudo cp /proc/$(pgrep -f "dex serve")/root/data/dex.db .
sqlite3 dex.db

.tables
.headers on
select * from auth_code;
select * from auth_request;
select * from client;
select * from connector;
select * from device_request;
select * from device_token;
select * from keys;
select * from migrations;
select * from offline_session;
select * from password;
select * from refresh_token;
