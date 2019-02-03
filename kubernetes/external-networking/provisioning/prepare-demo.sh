#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf

# Build container image with the demo services included
cd /vagrant

docker build -t httpbin:latest docker/httpbin
docker build -t client:latest docker/client

# generate certificates
curl -fsSL https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl
curl -fsSL https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssl*

mkdir -p certs
cfssl genkey -initca configs/cfssl-csr-root-ca-server.json | cfssljson -bare certs/server-root
cfssl genkey -initca configs/cfssl-csr-root-ca-client.json | cfssljson -bare certs/client-root
cfssl gencert -ca certs/server-root.pem -ca-key certs/server-root-key.pem configs/cfssl-csr-endentity-ingress.json | cfssljson -bare certs/ingress
cfssl gencert -ca certs/client-root.pem -ca-key certs/client-root-key.pem configs/cfssl-csr-endentity-client.json | cfssljson -bare certs/client
