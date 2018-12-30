#!/bin/bash -ex
#
# Description
#
#



# create resources
kubectl apply -f manifests/03-expose-service-externally-with-tls-passthrough.yaml

# provision server certificates
#
# note: this needs to be done before waiting (next command) because
# the existence of the secret is precondition for successful
# deployment due to volume mounts
kubectl -n inside-mesh create secret generic httpbin-certs --from-file=certs/httpbin.pem --from-file=certs/httpbin-key.pem --from-file=certs/client-root.pem

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# make request via gateway in passthrough mode
http --verify=certs/server-root.pem --cert=certs/client.pem --cert-key=certs/client-key.pem  https://httpbin.external.com/status/418

# note that the SNI must match with the configuration
http --verify=certs/server-root.pem --cert=certs/client.pem --cert-key=certs/client-key.pem  https://host1.external.com/status/418  || true  # ignore error from httpie

# see that the certificate really has the DNS SAN entry for httpbin.external.com
openssl s_client -connect httpbin.external.com:443 -servername httpbin.external.com 2>/dev/null | openssl x509 -text -noout

#kubectl -n inside-mesh logs -f client
#kubectl -n inside-mesh get pod client -o jsonpath={..terminated.exitCode}

# delete resources
kubectl delete -f manifests/03-expose-service-externally-with-tls-passthrough.yaml
