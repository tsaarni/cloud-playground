#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf


# Build container image with the demo services included
cd /vagrant

docker build -t httpbin:latest docker/httpbin
docker build -t client:latest docker/client
docker build -t sshd:latest docker/sshd

# install some tools required for the demo
apt-get install -y httpie sshpass
curl -fsSL https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl
curl -fsSL https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssl*


# generate certificates
mkdir -p certs
cfssl genkey -initca configs/cfssl-csr-root-ca-server.json | cfssljson -bare certs/server-root
cfssl genkey -initca configs/cfssl-csr-root-ca-client.json | cfssljson -bare certs/client-root
cfssl gencert -ca certs/server-root.pem -ca-key certs/server-root-key.pem configs/cfssl-csr-endentity-httpbin.json | cfssljson -bare certs/httpbin
cfssl gencert -ca certs/server-root.pem -ca-key certs/server-root-key.pem configs/cfssl-csr-endentity-gateway.json | cfssljson -bare certs/gateway
cfssl gencert -ca certs/server-root.pem -ca-key certs/server-root-key.pem configs/cfssl-csr-endentity-internal-gateway.json | cfssljson -bare certs/internal-gateway
cfssl gencert -ca certs/client-root.pem -ca-key certs/client-root-key.pem configs/cfssl-csr-endentity-client.json  | cfssljson -bare certs/client

# provision the externally issued ingress server certificate and key in a Secret for istio ingress gateway
kubectl create -n istio-system secret tls istio-ingressgateway-certs --key certs/gateway-key.pem --cert certs/gateway.pem
# client CA certificate for validating clients in mutual TLS setup
kubectl create -n istio-system secret generic istio-ingressgateway-ca-certs --from-file=certs/client-root.pem

# provision the ingress server certificate and key for internal ingress gateway, which is used to forward traffic from outside-mesh to inside-mes
kubectl create -n istio-system secret tls istio-internal-ingressgateway-certs --key certs/internal-gateway-key.pem --cert certs/internal-gateway.pem
# client CA certificate for validating clients in mutual TLS setup
kubectl create -n istio-system secret generic istio-internal-ingressgateway-ca-certs --from-file=certs/client-root.pem


# Note: istio-ingressgateway loads certificate automatically when the
# secret is created. However, the pod needs to be restarted if gateway
# certificate is re-generated and secret is updated. That is, it
# istio-ingressgateway only seems to notice new certificate but not
# renewed certificate.
#
#   kubectl create -n istio-system secret tls istio-ingressgateway-certs --key certs/gateway-key.pem --cert certs/gateway.pem  --dry-run -o yaml | kubectl apply -f -
#   kubectl -n istio-system delete pod -l app=istio-ingressgateway   # this will take ~minute



cat <<EOF >>/etc/hosts
127.0.0.1 host1.external.com
127.0.0.1 host2.external.com
127.0.0.1 host3.external.com
127.0.0.1 httpbin.external.com
EOF


echo "Ok"
