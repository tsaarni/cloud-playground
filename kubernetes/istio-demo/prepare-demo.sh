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
mkdir -p certs
cfssl genkey -initca configs/cfssl-csr-root-ca-server.json | cfssljson -bare certs/server-root
cfssl genkey -initca configs/cfssl-csr-root-ca-client.json | cfssljson -bare certs/client-root
cfssl gencert -ca certs/server-root.pem -ca-key certs/server-root-key.pem configs/cfssl-csr-endentity-httpbin.json | cfssljson -bare certs/httpbin
cfssl gencert -ca certs/server-root.pem -ca-key certs/server-root-key.pem configs/cfssl-csr-endentity-gateway.json | cfssljson -bare certs/gateway
cfssl gencert -ca certs/client-root.pem -ca-key certs/client-root-key.pem configs/cfssl-csr-endentity-client.json  | cfssljson -bare certs/client


# add host aliases in order to use TLS SNI
cat <<EOF >>/etc/hosts
127.0.0.1 host1.external.com
127.0.0.1 host2.external.com
127.0.0.1 host3.external.com
EOF

echo "Ok"

