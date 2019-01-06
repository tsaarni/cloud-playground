#!/bin/bash -ex
#
# Description
#
# In this demo a service is running inside the service mesh and
# external client accesses it using SSH.  Istio ingress-gateway is
# configured in TCP passthrough mode to route SSH traffic through the
# ingress gateway to the service.
#
# Note that SSH traffic is tunneled using TLS connection between the
# gateway and istio-proxy in the sidecar.
#

# Create resources
kubectl apply -f sec-ingress--passthrough-and-terminate-ssh-in-service.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=sshd

# establish SSH connection via gateway in passthrough mode
sshpass -p password ssh sshuser@host1.external.com -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "echo Hello world!"

# Delete resources
kubectl delete -f sec-ingress--passthrough-and-terminate-ssh-in-service.yaml
