#!/bin/bash -ex
#
# Description
#
# In this demo a service is running inside service mesh and an
# external client accesses it using HTTPS.  Istio ingress-gateway
# terminates the external TLS connection on behalf of the service.
#
# The TLS connection between external client and Istio ingress gateway
# is mutually authenticated.  Gateway validates that it is signed by
# an trusted CA.
#
#
# Note that client authentication in ingress-gateway is not currently
# feasible in practise, since the client identity is "lost" in the
# ingress gateway and further authorization decisions cannot be made.
#
# There is an option in Gateway resource to set list of allowed SANs
# of the client certificate (found in Server.TLSOptions) but there is
# no option to validate e.g. CN in SubjectName.  There is no option to
# auhtorize access to particular resources according to client
# identity.
#
# Istio 1.1 will give access to existing feature in Envoy to send
# client certificate information in "x-forwarded-client-cert" HTTP
# header
#
# For further information see
#   - https://github.com/istio/istio/issues/8263, https://github.com/istio/istio/pull/8468
#   - https://www.envoyproxy.io/docs/envoy/latest/configuration/http_conn_man/headers#config-http-conn-man-headers-x-forwarded-client-cert
#

# create resources
kubectl apply -f sec-ingress--terminate-mutual-tls-in-ingress-gateway.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# wait for envoy to be configured
sleep 1

# make a successful HTTPS request to the service via istio-ingressgateway
# note that the client certificate and key is provided in the command
http --verify certs/server-root.pem --cert certs/client.pem --cert-key certs/client-key.pem https://host1.external.com/status/418

# the connection will fail if we try to establish the connection without client certificate
http --verify certs/server-root.pem https://host1.external.com/status/418 || true  # ignore error from httpie

# Note that service does NOT receive any information about client
# identity currently ("x-forwarded-client-cert" header will be
# available in Istio 1.1)
http --verify certs/server-root.pem --cert certs/client.pem --cert-key certs/client-key.pem https://host1.external.com/headers

# delete resources
kubectl delete -f sec-ingress--terminate-mutual-tls-in-ingress-gateway.yaml
