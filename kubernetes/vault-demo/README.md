# Demo: Vault on Kubernetes

## Preparations

### Issue TLS certificate

Lets use the internal CA in Kubernetes to issue certificate for Vault.
For further information see
[here](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/).

Download cfssl and cfssljson from [here](https://pkg.cfssl.org/) or
compile from source according to instructions
[here](https://github.com/cloudflare/cfssl/).

Generate keypair and CSR.

    cfssl genkey certs/vault-csr.json | cfssljson -bare certs/vault
    cfssl certinfo -csr certs/vault.csr

Submit CSR to Kubernetes

    cat <<EOF | kubectl create -f -
    apiVersion: certificates.k8s.io/v1beta1
    kind: CertificateSigningRequest
    metadata:
      name: vault
    spec:
      groups:
      - system:authenticated
      request: $(cat certs/vault.csr | base64 | tr -d '\n')
      usages:
      - digital signature
      - key encipherment
      - server auth
    EOF

Check that the CSR was submitted correctly.  The status should show `Pending`.

    kubectl describe csr

Approve the CSR. The status should change to `Approved,Issued`.

    kubectl certificate approve vault

If status remains only `Approved` but not `Issued` and you are running
minikube, see [Minikube Workarounds](#minikube-workarounds) in this readme.

Run following to fetch the certificate and check the certificate content:

    kubectl get csr vault -o jsonpath='{.status.certificate}' | base64 -d > certs/vault.pem
    cfssl certinfo -cert certs/vault.pem


### Upload certificate and key as Secret

    kubectl create secret generic vault-cert --from-file=vault.pem=certs/vault.pem --from-file=vault-key.pem=certs/vault-key.pem


### Upload Vault Configuration File

    kubectl create configmap vault-config --from-file=configs/vault.hcl


## Deploy Vault

    kubectl apply -f manifests/vault-ephemeral-storage.yaml


    # run tests with vault client
    kubectl run --rm -it client --image=vault:0.8.3 ash

    # set the connection params
    export VAULT_ADDR="https://vault:8200"
    export VAULT_CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

    # init will print unseal key and initial root tokenn
    vault init -key-shares=1 -key-threshold=1
    vault unseal <unseal key 1>
    vault auth <initial root token>




## Minikube Workarounds

These workarounds apply to Minikube v0.22.2 with Kubernetes v1.7.5.

* Kubernetes controller-manager CA is not enabled by default: see
  [this ticket](https://github.com/kubernetes/minikube/issues/1647) Use
  the `--extra-config` parameters listed below.
* Kube-dns does not work if RBAC is enabled: see
  [this ticket](https://github.com/kubernetes/minikube/issues/1734)
  and the workaround roles and rolebindings near the bottom of the
  ticket.

Here is a command for enabling RBAC and apiserver internal CA:

    minikube start --extra-config=apiserver.Authorization.Mode=RBAC --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key"
