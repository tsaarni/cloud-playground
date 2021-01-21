# Demo: configure Keycloak with LDAP + StartTLS + SASL EXTERNAL for client authentication

> **⚠ WARNING:**
>
> LDAP client authentication with SASL EXTERNAL is not officially documented or supported by Keycloak.
>
> The method presented here is based on the fact that Keycloak will transparently pass the LDAP authentication type to Java LDAP library without validating the input.
> This makes it possible to enable SASL EXTERNAL client authentication "under the covers" by using the Keycloak Administration REST API.
>
> Pull request for official support is submitted at https://github.com/keycloak/keycloak/pull/7365 but it is unclear if this PR will progress.

This demo is running on Kubernetes and [kind](https://kind.sigs.k8s.io/).
Steps to reproduce the demo are listed below.

## Preparations

```bash
# start new cluster
kind delete cluster --name keycloak
kind create cluster --config configs/kind-cluster-config.yaml --name keycloak

# build a container for openldap
docker build docker/openldap/ -t localhost/openldap:latest
kind load docker-image localhost/openldap:latest --name keycloak

# create configmap with ldif file that will be the content of the openldap server during the demo
kubectl create configmap openldap-ldif --from-file=configs/database.ldif --from-file=configs/users-and-groups.ldif --dry-run=client -o yaml | kubectl apply -f -

# deploy openldap
kubectl apply -f manifests/openldap.yaml

# deploy jetstack certificate manager and create certificates for the demo
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
kubectl apply -f manifests/certificates.yaml   # will give error until cert-manager is running

# deploy ingress controller
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml

# deploy postgres
kubectl apply -f manifests/postgres.yaml

# deploy keycloak
kubectl apply -f manifests/keycloak.yaml
```

When finished, Keycloak will be accessible at http://keycloak.127-0-0-191.nip.io with username `admin` and password `admin`.


## Configure LDAP federation

```bash
# get admin token
TOKEN=$(http --form POST http://keycloak.127-0-0-191.nip.io/auth/realms/master/protocol/openid-connect/token username=admin password=admin grant_type=password client_id=admin-cli | jq -r .access_token)

# create the LDAP provider
http -v POST http://keycloak.127-0-0-191.nip.io/auth/admin/realms/master/components Authorization:"bearer $TOKEN" < requests/create-ldap-provider.json

# check that the provider was created
http -v "http://keycloak.127-0-0-191.nip.io/auth/admin/realms/master/components?parent=master&type=org.keycloak.storage.UserStorageProvider" Authorization:"bearer $TOKEN"

# try login as LDAP user
http -v --form POST http://keycloak.127-0-0-191.nip.io/auth/realms/master/protocol/openid-connect/token username=user password=user grant_type=password client_id=admin-cli

# reload key-store and reinitialize key-manager (needed after client certificate is rotated)
kubectl exec -it $(kubectl get pod -l app=keycloak -o jsonpath='{.items[0].metadata.name}') -- /opt/jboss/keycloak/bin/jboss-cli.sh --connect --commands="/subsystem=elytron/key-store=default-key-store:load()"
kubectl exec -it $(kubectl get pod -l app=keycloak -o jsonpath='{.items[0].metadata.name}') -- /opt/jboss/keycloak/bin/jboss-cli.sh --connect --commands="/subsystem=elytron/key-manager=default-key-manager:init()"
```

## Debugging

```bash
# read logs
kubectl logs $(kubectl get pod -l app=keycloak -o jsonpath='{.items[0].metadata.name}') -f
kubectl logs $(kubectl get pod -l app=openldap -o jsonpath='{.items[0].metadata.name}') -f

# reset persistent data stored to postgres
kubectl delete -f manifests/postgres.yaml
kubectl delete pvc -l app=postgres
kubectl apply -f manifests/postgres.yaml
kubectl rollout restart deployment keycloak

# execute ldapsearch
kubectl exec -it $(kubectl get pod -l app=openldap -o jsonpath='{.items[0].metadata.name}') -- ldapsearch -H ldapi:/// -b cn=config

# run jboss cli
kubectl exec -it $(kubectl get pod -l app=keycloak -o jsonpath='{.items[0].metadata.name}') -- /opt/jboss/keycloak/bin/jboss-cli.sh --connect

# see decrypted LDAP packet capture
sudo nsenter --target $(pidof slapd) --net wireshark -f "port 389 or port 636" -k -o tls.keylog_file:/tmp/keycloak-kind/wireshark-keys.log

# check expiration period from certificate
kubectl get secret keycloakcert -o jsonpath='{..tls\.crt}' | base64 -d | openssl x509 -text -noout
```
