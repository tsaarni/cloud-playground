#!/bin/bash -ex
#
# Description
#
# This demo explores how Istio implements TLS within the service mesh.
# The demo accesses the mesh directly from within Kubernetes worker
# node.
#

# create resources
kubectl apply -f sec-explore--istio-proxy-internals.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# wait for envoy to be configured
sleep 1


###########################################
#
# Mutual TLS authentication between pods
#

# request sent directly to the pod IP or Service's Cluster IP will NOT work
# because the connection is forwarded to Envoy proxy which accepts only TLS
http http://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP})/status/418 || true  # ignore error from httpie
http http://$(kubectl -n inside-mesh get service -l app=httpbin -o jsonpath={.items..clusterIP})/status/418 || true  # ignore error from httpie

# We can try to establish TLS connection instead, but it also fails
# since Envoy has been configured to accept only authenticated clients
# (mutual TLS authentication).
#
# Note that we need to add --verify=no because we access directly via
# IP and not hostname, and because Istio uses SPIFFE certificates which
# are not valid according to standard verification procedures (no
# hostname in SubjectAltName)

http --verify=no https://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}):80/status/418 || true  # ignore error from httpie
http --verify=no https://$(kubectl -n inside-mesh get service -l app=httpbin -o jsonpath={.items..clusterIP}):80/status/418 || true  # ignore error from httpie


# In order to authenticate we need to fetch the Istio default account
# certificate and key from Kubernetes Secret "istio.default"
kubectl -n inside-mesh get secrets istio.default -o jsonpath={.data.cert-chain\\.pem} | base64 -d > certs/istio-default-cert-chain.pem
kubectl -n inside-mesh get secrets istio.default -o jsonpath={.data.key\\.pem}        | base64 -d > certs/istio-default-key.pem
kubectl -n inside-mesh get secrets istio.default -o jsonpath={.data.root-cert\\.pem}  | base64 -d > certs/istio-default-root-cert.pem

# Lets check what is in the client certificate
openssl x509 -in certs/istio-default-cert-chain.pem -text -noout

# Now requests to service will work since we provide client certificate
http --verify=no --cert certs/istio-default-cert-chain.pem --cert-key certs/istio-default-key.pem https://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}):80/status/418
http --verify=no --cert certs/istio-default-cert-chain.pem --cert-key certs/istio-default-key.pem https://$(kubectl -n inside-mesh get service -l app=httpbin -o jsonpath={.items..clusterIP}):80/status/418

# To see the SPIFFE server certificate we can run openssl s_client.
# It is the same default certificate which we used as a client cert.
# Note that openssl s_client does not verify hostname by default so it succeeds
echo Q | openssl s_client -CAfile certs/istio-default-root-cert.pem -cert certs/istio-default-cert-chain.pem -key certs/istio-default-key.pem -connect $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP})/:80 2>/dev/null | openssl x509 -text -noout


###########################################
#
# Create new service account and see how Istio Citadel automatically creates
# SPIFFE cert for that
#

kubectl -n inside-mesh create serviceaccount my-service-account

# check what certificates got generated
# note the algorithm and key length
#   - RSA 2048
# note the validity period of the certificates
#   - workload cert 3 months
#   - root CA cert  1 year
kubectl -n inside-mesh get secret istio.my-service-account -o jsonpath={..'cert-chain\.pem'} | base64 -d | openssl x509 -text -noout
kubectl -n inside-mesh get secret istio.my-service-account -o jsonpath={..'root-cert\.pem'} | base64 -d | openssl x509 -text -noout

# show all certificates that istio citadel has created
kubectl get secret --all-namespaces | grep istio.io/key-and-cert

# compare this to the list of service accounts defined in the system
kubectl get serviceaccount --all-namespaces

# note the secret where CA key is stored by istio citadel
kubectl -n istio-system get secret istio-ca-secret -o json
kubectl -n istio-system get secrets istio-ca-secret -o jsonpath="{..ca-key\.pem}"| base64 -d | openssl pkey -text -noout


###########################################
#
# Show HTTP headers added by envoy
#

http --verify=no --cert certs/istio-default-cert-chain.pem --cert-key certs/istio-default-key.pem https://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}):80/headers


###########################################
#
# Show encrypted traffic between pods
#

# Check that the internal communication is encrypted since we have enabled Istio TLS policy.
# First put tcpdump to background to capture traffic from httpbin pod
sudo tcpdump -vvvv -s 0 -A -i any -n src port 80 and host $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}) &
TCPDUMP_PID=$!
http --verify=no --cert certs/istio-default-cert-chain.pem --cert-key certs/istio-default-key.pem https://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}):80/headers >/dev/null 2>/dev/null

# kill tcpdump
sudo kill $(pgrep -P $TCPDUMP_PID)


###########################################
#
# What is in the sidecar
#

# check what processes are running inside the istio-proxy sidecar
kubectl -n inside-mesh exec $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath='{.items[0].metadata.name}') --container=istio-proxy -- sh -cx "id; ps -nef; lsof -itcp -n"

# list the iptables NAT rules that istio creates
containerid=$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath='{..containerStatuses[?(@.name=="istio-proxy")].containerID}')  # find the docker container id of the istio-proxy sidecar
containerid=${containerid#docker://}  # strip out the docker:// prefix
docker exec --privileged --user=root $containerid iptables -t nat -S  # run iptables command in privileged mode as root user

# Note following from the output of previous commands
#
#   - envoy proxy is listening port 15001 and running with uid=1337 gid=1337
#   - inbound connections to port 80 are redirected to port 15001
#   - outbound connections are redirected to port 15001, except the ones
#     originated by process with uid=1337 gid=1337
#   - envoy admin interface is listening 127.0.0.1:15000

# explore the admin interface of envoy proxy
#  https://www.envoyproxy.io/docs/envoy/latest/operations/admin
# note that part of the admin interface primitives are available also via `istioctl` (see below)
kubectl -n inside-mesh exec $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath='{.items[0].metadata.name}') --container=istio-proxy -- sh -cx "curl -s http://localhost:15000/help"


###########################################
#
# Using istioctl
#
# See also
#   - https://istio.io/help/ops/traffic-management/proxy-cmd/
#

istioctl proxy-status

istioctl proxy-config cluster -n inside-mesh $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config listeners -n inside-mesh $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath='{.items[0].metadata.name}')

istioctl authn tls-check


# delete resources
kubectl delete -f sec-explore--istio-proxy-internals.yaml
