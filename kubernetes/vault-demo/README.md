# Demo: Vault on Kubernetes

## Minikube

To enable Kubernetes CA in minikube installation, start it by running

    minikube start --extra-config=apiserver.Authorization.Mode=RBAC --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key"


## Preparations

Build container by following instructions in [docker/README.md](docker/README.md)

Generate server certificate for Vault

    # install cfssl tools to generate key and CSR
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
    kubectl get csr vault -o jsonpath='{.status.certificate}' | base64 -d > vault.pem

    # remove the CSR
    kubectl delete csr vault

    # check that the certificate looks ok
    cfssl certinfo -cert vault.pem


## Deploy Vault

Create configmap for `vault.hcl` configuration file

    kubectl create configmap vault-config --from-file=configs/vault.hcl
    kubectl get configmap vault-config -o json | jq .


Create secret for Vault HTTPS certificate and private key

    kubectl create secret generic vault-cert --from-file=vault.pem --from-file=vault-key.pem
    kubectl get secret vault-cert -o json | jq .


Create deployment

    kubectl apply -f manifests/vault.yaml


Test deployment

    # find out the name of the pod
    kubectl get pods

    # execute shell inside the container
    kubectl exec -it vault-NNNNNNNNNN ash


## Deploy client

Create secret for CA certificate

    kubectl create secret generic ca-cert



    kubectl run --rm -it --image=alpine ash
    apk -U add curl
    curl -v --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt https://vault:8200
