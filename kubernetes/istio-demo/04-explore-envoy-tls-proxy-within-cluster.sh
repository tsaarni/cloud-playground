#!/bin/bash -ex
#
# Description
#
# Explore various ways to access the service from host (worker node),
# to demonstrate how Istio TLS is implemented.
#

# create resources
kubectl apply -f manifests/04-explore-envoy-tls-proxy-within-cluster.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# wait for envoy to be configured
sleep 1

# request sent directly to the pod IP or Service's Cluster IP will NOT work anymore
# because the connection is forwarded to Envoy proxy which accepts only TLS
http http://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP})/status/418 || true  # ignore error from httpie
http http://$(kubectl -n inside-mesh get service -l app=httpbin -o jsonpath={.items..clusterIP})/status/418 || true  # ignore error from httpie

# We can try to create TLS connectivity instead, but it also
# fails. This is because we dont have client certificate and Istio has
# been configured to accept only authenticated clients.
#
# Note that we need to add --verify=no because we access directly via
# IP and not hostname, and because server has SPIFFE certificate which
# is not valid according to standard verification procedures (no
# hostname or IP in Subject or # SubjectAltName)

http --verify=no https://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}):80/status/418 || true  # ignore error from httpie
http --verify=no https://$(kubectl -n inside-mesh get service -l app=httpbin -o jsonpath={.items..clusterIP}):80/status/418 || true  # ignore error from httpie


# In order to authenticate we need to fetch the Istio default account
# certificate and key
kubectl -n inside-mesh get secrets istio.default -o jsonpath={.data.cert-chain\\.pem} | base64 -d > certs/istio-default-cert-chain.pem
kubectl -n inside-mesh get secrets istio.default -o jsonpath={.data.key\\.pem}        | base64 -d > certs/istio-default-key.pem
kubectl -n inside-mesh get secrets istio.default -o jsonpath={.data.root-cert\\.pem}  | base64 -d > certs/istio-default-root-cert.pem

# show the client certificate
openssl x509 -in certs/istio-default-cert-chain.pem -text -noout

# Now request to service will work since we provide client certificate
http --verify=no --cert certs/istio-default-cert-chain.pem --cert-key certs/istio-default-key.pem https://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}):80/status/418
http --verify=no --cert certs/istio-default-cert-chain.pem --cert-key certs/istio-default-key.pem https://$(kubectl -n inside-mesh get service -l app=httpbin -o jsonpath={.items..clusterIP}):80/status/418

# To see the SPIFFE server certificate you can run openssl s_client.
# It is the same default certificate which we used as a client cert.
# Note that openssl s_client does not verify hostname by default so it succeeds
printf "GET /status/418 HTTP/1.1\nHost: host1.external.com\nConnection: close\n\n" | openssl s_client -CAfile certs/istio-default-root-cert.pem -cert certs/istio-default-cert-chain.pem -key certs/istio-default-key.pem -connect $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP})/:80 2>/dev/null | openssl x509 -text -noout

# delete resources
kubectl delete -f manifests/04-explore-envoy-tls-proxy-within-cluster.yaml
