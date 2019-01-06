#!/bin/bash -ex
#
# Description
#
# In this demo a service is running inside service mesh and an
# external client accesses it using HTTPS.  Istio ingress-gateway
# terminates the external TLS connection on behalf of the service.
#
# The request is routed to the service by using "Host:" HTTP header.
#

# create resources
kubectl apply -f sec-ingress--terminate-tls-in-ingress-gateway.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# wait for envoy to be configured
sleep 1

# make a successful HTTPS request to the service via istio-ingressgateway
http --verify certs/server-root.pem https://host1.external.com/status/418

# check the server certificate that is sent by istio-ingressgateway during TLS handshake
echo Q | openssl s_client -CAfile certs/server-root.pem -connect host1.external.com:443 2>/dev/null | openssl x509 -text -noout

# the certificate is the same that has been previously provisioned to Secret by script provisioning/prepare-demo.sh
kubectl -n istio-system get secrets istio-ingressgateway-certs -o jsonpath={..'tls\.crt'} | base64 -d | openssl x509 -text -noout

# Note that in this demo TLS SNI is not used by istio-ingressgateway
# for routing the request. From TLS perspective any servername in SNI
# is ok.
#
# Test following variants to demonstrate routing:
#   - request with "Host: host1.external.com" and TLS SNI "foo.bar.baz" -> TLS connection ok, HTTP request ok
#   - request with "Host: foo.barbaz" and TLS SNI "host1.external.com"  -> TLS connection ok, HTTP request fails
printf "GET /status/418 HTTP/1.1\nConnection: close\nHost: host1.external.com\n\n" | openssl s_client -quiet -CAfile certs/server-root.pem -connect host1.external.com:443 -servername foo.bar.baz
printf "GET /status/418 HTTP/1.1\nConnection: close\nHost: foo.bar.baz\n\n" | openssl s_client -quiet -CAfile certs/server-root.pem -connect host1.external.com:443 -servername host1.external.com

# delete resources
kubectl delete -f sec-ingress--terminate-tls-in-ingress-gateway.yaml
