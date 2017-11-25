# How to issue certificate with Kubernetes builtin CA

This example shows how to use the internal CA in Kubernetes to issue
certificate.  For further information see
[here](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/).

Download cfssl and cfssljson from [here](https://pkg.cfssl.org/) or
compile from source according to instructions
[here](https://github.com/cloudflare/cfssl/).

Generate keypair and CSR.

    cfssl genkey certs/myserver-csr.json | cfssljson -bare certs/myserver
    cfssl certinfo -csr certs/myserver.csr

Submit CSR to Kubernetes

    cat <<EOF | kubectl create -f -
    apiVersion: certificates.k8s.io/v1beta1
    kind: CertificateSigningRequest
    metadata:
      name: myserver
    spec:
      groups:
      - system:authenticated
      request: $(cat certs/myserver.csr | base64 | tr -d '\n')
      usages:
      - digital signature
      - key encipherment
      - server auth
    EOF

Check that the CSR was submitted correctly.  The status should show `Pending`.

    kubectl describe csr

Approve the CSR. The status should change to `Approved,Issued`.

    kubectl certificate approve myserver

If status remains only `Approved` but not `Issued` and you are running
minikube, see [Minikube Workarounds](#minikube-workarounds) in this readme.

Run following to fetch the certificate and check the certificate content:

    kubectl get csr myserver -o jsonpath='{.status.certificate}' | base64 -d > certs/myserver.pem
    cfssl certinfo -cert certs/myserver.pem


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
