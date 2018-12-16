#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf


# Build container image with the demo services included
cd /vagrant

docker build -t httpbin:latest docker/httpbin
docker build -t demo:latest docker/demo


# Create namespaces `inside` and `outside`.  The first is where
# automatic istio sidecar injection is enabled and second is hosting
# microservices outside service mesh

kubectl create ns inside
kubectl create ns outside

kubectl label namespace inside istio-injection=enabled


# install some tools for the demo
apt-get install -y httpie


# install cfssl
curl -fsSL https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl
curl -fsSL https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssl*


# generate certificates
cfssl genkey -initca configs/cfssl-csr-root-ca-server.json | cfssljson -bare server-root
cfssl genkey -initca configs/cfssl-csr-root-ca-client.json | cfssljson -bare client-root
cfssl gencert -ca server-root.pem -ca-key server-root-key.pem configs/cfssl-csr-endentity-httpbin.json | cfssljson -bare httpbin
cfssl gencert -ca server-root.pem -ca-key server-root-key.pem configs/cfssl-csr-endentity-gateway.json | cfssljson -bare gateway
cfssl gencert -ca client-root.pem -ca-key client-root-key.pem configs/cfssl-csr-endentity-client.json  | cfssljson -bare client


cat <<EOF >>/etc/hosts
127.0.0.1 host1.external.com
127.0.0.1 host2.external.com
127.0.0.1 host3.external.com
EOF
