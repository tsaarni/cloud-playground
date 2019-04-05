
# install contour
kubectl apply -f https://j.hept.io/contour-deployment-rbac

# install tools for tests
apt-get install -y httpie
curl -fsSL https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl
curl -fsSL https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssl*

# create server cert and key for contour
mkdir -p certs
cfssl genkey -initca configs/cfssl-csr-root-ca-server.json | cfssljson -bare certs/server-root
cfssl gencert -ca certs/server-root.pem -ca-key certs/server-root-key.pem configs/cfssl-csr-endentity-tcpecho.json | cfssljson -bare certs/tcpecho
cfssl gencert -ca certs/server-root.pem -ca-key certs/server-root-key.pem configs/cfssl-csr-endentity-httpbin.json | cfssljson -bare certs/httpbin

# create secrets for contour
kubectl create secret tls tcpecho-tls --cert=certs/tcpecho.pem --key=certs/tcpecho-key.pem
kubectl create secret tls httpbin-tls --cert=certs/httpbin.pem --key=certs/httpbin-key.pem

# add mDNS hostname for Contour's external IP
#   - depends on https://github.com/tsaarni/k8s-external-mdns
#   - wait for a few seconds for external-dns to populate /etc/avahi/hosts
kubectl -n heptio-contour annotate service contour external-dns.alpha.kubernetes.io/hostname=tcpecho.local

# TODO: avahi cannot resolve several host names to single address
# WORKAROUND: put the addresses in /etc/hosts instead
# kubectl -n heptio-contour annotate service contour external-dns.alpha.kubernetes.io/hostname=tcpecho.local,httpbin.local
