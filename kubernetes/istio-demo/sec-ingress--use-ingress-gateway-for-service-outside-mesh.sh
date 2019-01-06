#!/bin/bash -ex
#
# Description
#
# In this demo two services are running outside service mesh:
#   - httpbin in HTTPS mode
#   - sshd service
#
# Ingress gateway is configured in passthrough mode to forward the
# traffic to the services.


# create resources
# Note that server credentials are provisioned here also
kubectl apply -f sec-ingress--use-ingress-gateway-for-service-outside-mesh.yaml && \
kubectl -n outside-mesh create secret generic httpbin-certs --from-file=certs/httpbin.pem --from-file=certs/httpbin-key.pem --from-file=certs/client-root.pem

# wait until deployed
kubectl -n outside-mesh wait deployment --timeout=60s --for condition=available -l app=sshd
kubectl -n outside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# make HTTP request via gateway in passthrough mode.
http --verify=certs/server-root.pem --cert=certs/client.pem --cert-key=certs/client-key.pem  https://httpbin.external.com/status/418

# establish SSH connection via gateway in passthrough mode
sshpass -p password ssh sshuser@host1.external.com -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "echo Hello world!"

# delete resources
kubectl delete -f sec-ingress--use-ingress-gateway-for-service-outside-mesh.yaml
