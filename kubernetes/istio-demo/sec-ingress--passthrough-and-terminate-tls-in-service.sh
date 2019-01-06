#!/bin/bash -ex
#
# Description
#
# In this demo a service is running inside the service mesh and an
# external client accesses it using HTTPS.  Istio ingress-gateway is
# configured in TLS passthrough mode.  The service terminates TLS
# itself.
#
# Note that in this demo also client authenticates itself, and since
# the service terminates TLS itself, it is able to see the client
# certificate from external client. Client can implement authorization
# according to client identity (not part of this demo).
#

# create resources
# Note that server credentials are provisioned here also
kubectl apply -f sec-ingress--passthrough-and-terminate-tls-in-service.yaml && \
kubectl -n inside-mesh create secret generic httpbin-certs --from-file=certs/httpbin.pem --from-file=certs/httpbin-key.pem --from-file=certs/client-root.pem

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# make a successful request via gateway in passthrough mode.
http --verify=certs/server-root.pem --cert=certs/client.pem --cert-key=certs/client-key.pem  https://httpbin.external.com/status/418

# Check that the certificate really originates from the service instead of the Istio ingress-gateway.
# See that the DNS SAN entry is "httpbin.external.com" (provisioned to the service)
# instead of "host1.external.com" or "host2.external.com" (provisioned to gateway)
openssl s_client -CAfile certs/server-root.pem -connect httpbin.external.com:443 -servername httpbin.external.com 2>/dev/null | openssl x509 -text -noout

# the connection will fail if we try to establish the connection without client certificate
http --verify=certs/server-root.pem https://httpbin.external.com/status/418 || true  # ignore error from httpie

# Connection will fail when TLS SNI does not match with "httpbin.external.com"
# which is used in the match rule in the configuration ("host1.external.com" is used in the request below)
printf "GET /status/418 HTTP/1.1\r\nConnection: close\r\nHost: httpbin.external.com\r\n\r\n" | openssl s_client -quiet -CAfile certs/server-root.pem -cert certs/client.pem -key certs/client-key.pem -connect httpbin.external.com:443 -servername host1.external.com || true  # ignore error


#kubectl -n inside-mesh logs -f client
#kubectl -n inside-mesh get pod client -o jsonpath={..terminated.exitCode}

# delete resources
kubectl delete -f sec-ingress--passthrough-and-terminate-tls-in-service.yaml
