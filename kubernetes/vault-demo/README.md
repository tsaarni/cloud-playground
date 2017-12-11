# Demo: Vault on Kubernetes

## Preparation

### Minikube

This demo can be executed on [minikube](https://github.com/kubernetes/minikube). To enable Kubernetes CA in minikube installation, start it by running

    minikube start --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key"


### Build Containers

The demo requires two containers: vault and client.  To build these
containers run following commands

    # make sure that the containers are available on the kubernetes
    # nodes, e.g. if running minikube to run the demo then execute
    eval $(minikube docker-env)

    docker build -t demo-vault:0.9.0 docker/vault
    docker build -t demo-client:1.0.0 docker/client


## Generate Certificate for Vault

Kubernetes runs a CA within the Kubernetes API server.  In this demo
the CA is used to issue Vault certificate.  Kubernetes distributes
the CA certificate to all containers automatically, because the CA is
used as a trusted certificate to communicate with the API server.
This makes it convenient for the demo, since clients can refer to
`/run/secrets/kubernetes.io/serviceaccount/ca.crt` as the trusted CA
certificate.

Generate server certificate for Vault

    # compile cfssl tools from source or alternatively download
    # pre-compiled binaries from https://pkg.cfssl.org/
    go get -v -u github.com/cloudflare/cfssl/cmd/...

    # generate private key and certificate signing request for Vault
    cfssl genkey configs/cfssl-vault-server-csr.json | cfssljson -bare vault

    # send CSR to kubernetes CA
    CSR=$(cat vault.csr | base64 | tr -d '\n') envsubst < manifests/vault-csr.yaml | kubectl create -f -

    # approve the request
    kubectl certificate approve vault

    # check that status changed to `Approved,Issued`.
    kubectl describe csr vault

    # fetch the certificate
    kubectl get csr vault -o jsonpath='{.status.certificate}' | base64 --decode > vault.pem

    # remove the CSR
    kubectl delete csr vault

    # check that the certificate looks ok
    cfssl certinfo -cert vault.pem


## Deploy Vault

Create configmap for `vault.hcl` configuration file

    kubectl create configmap vault-config --from-file=configs/vault.hcl

    # check that the configmap got created
    kubectl get configmap vault-config -o json | jq .


Create secret for Vault HTTPS certificate and private key.  Note that
in this case the private key is stored in etcd backend storage which
(by default) is not encrypted.

    kubectl create secret generic vault-cert --from-file=vault.pem --from-file=vault-key.pem

    # check that the secret got created
    kubectl get secret vault-cert -o json | jq .


Create persistent volume for storage backend of Vault

    kubectl apply -f manifests/vault-pvc.yaml


Create deployment

    kubectl apply -f manifests/vault.yaml

    # check that status is `Running`
    kubectl get pods


## Configure Vault

Execute new shell inside Vault container

    # find vault pod name
    kubectl get pods
    kubectl exec -it vault-NNNNNNNNN ash


Initialize Vault in order to generate key shares

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    PUT https://localhost:8200/v1/sys/init \
    secret_shares:=1 secret_threshold:=1

    # sys/init end-point will return key and root_token fields,
    # set them to environment variables for using them later
    export UNSEAL_KEY=NNNNNNNNNNNNN
    export ROOT_TOKEN=NNNNNNNNNNNNN


Unseal Vault with unseal key which was generated in previous step

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    PUT https://localhost:8200/v1/sys/unseal \
    key=$UNSEAL_KEY


Get the status, it should return `initialized: true` and `sealed: false`

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    GET https://localhost:8200/v1/sys/health


Enable Kubernetes auth backend:

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    POST https://localhost:8200/v1/sys/auth/kubernetes \
    "X-Vault-Token: $ROOT_TOKEN" \
    type=kubernetes


Configure Kubernetes auth backend

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    POST https://localhost:8200/v1/auth/kubernetes/config \
    "X-Vault-Token: $ROOT_TOKEN" \
    kubernetes_host=https://kubernetes kubernetes_ca_cert=@/run/secrets/kubernetes.io/serviceaccount/ca.crt token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token


Create access policy called `foo-reader` that allows `read` access to
`secret/foo`

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    POST https://localhost:8200/v1/sys/policy/foo-reader \
    "X-Vault-Token: $ROOT_TOKEN" \
    policy="path \"secret/foo\" { capabilities = [\"read\"] }"


Create new role called `demo-role` and associate it to policy
`foo-reader`

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    POST https://localhost:8200/v1/auth/kubernetes/role/demo-role \
    "X-Vault-Token: $ROOT_TOKEN" \
    bound_service_account_names=vault-client bound_service_account_namespaces=default policies=foo-reader


Create two secrets: `secret/foo` and `secret/bar`

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    POST https://localhost:8200/v1/secret/foo \
    "X-Vault-Token: $ROOT_TOKEN" \
    mysecret=foo

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    POST https://localhost:8200/v1/secret/bar \
    "X-Vault-Token: $ROOT_TOKEN" \
    mysecret=bar


## Access Vault with Kubernetes Service Account

Create client deployment and service account `vault-client`.  Execute
shell inside the client container

    kubectl apply -f manifests/client.yaml

    # find out the client pod id
    kubectl get pods
    kubectl exec -it client-NNNNNNNN ash


Login to Vault with the Service Account that was injected to the pod
by Kubernetes

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    POST https://vault:8200/v1/auth/kubernetes/login \
    role=demo-role jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token

    # auth/kubernetes/login end-point will return field client_token,
    # set it to environment variable
    export CLIENT_TOKEN=NNNNNNNNN


Read secret `secret/foo`

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    GET https://vault:8200/v1/secret/foo \
    "X-Vault-Token: $CLIENT_TOKEN"


Try to access `secret/bar`, the policy will refuse access

    http -v --verify=/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    GET https://vault:8200/v1/secret/bar \
    "X-Vault-Token: $CLIENT_TOKEN"
