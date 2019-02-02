#!/bin/bash -ex
#
# Description
#
# This script demonstrates TLS origination towards cluster external
# service using egress gateway.  Egress gateway authenticates itself
# with client certificate towards the external service.
#

# create resources
kubectl apply -f sec-egress--mtls-originatation-from-egress-gateway.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=client


# start httpbin as external service, running on host os with plain
# docker, outside kubernetes cluster network
# require client certificate from clients
docker run --rm --volume $PWD/certs:/etc/certs --publish 8443:443 httpbin gunicorn -b 0.0.0.0:443 --access-logfile -  --certfile /etc/certs/httpbin.pem --keyfile /etc/certs/httpbin-key.pem --cert-reqs 2 --ca-certs /etc/certs/client-root.pem httpbin:app


# check that the outbound connection is going through egress gateway to httpbin.org
# by capturing the traffic from client envoy sidecar
sudo tcpdump -vvvv -s 0 -A -i any port 8443 and host $(kubectl -n istio-system get pod -l istio=egressgateway -o jsonpath={.items..podIP}) &
TCPDUMP_PID=$!

# use client pod inside the mesh to call HTTPS service external to the cluster
# - 10.0.2.15 is the default address that virtualbox will assign to the first network adapter of the VM
# - use xip.io to resolve address with DNS
kubectl -n inside-mesh exec -it $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- \
        ash -c "http http://10.0.2.15.xip.io/status/418 </dev/null"

# observe the tcpdump output
# it shows traffic between egressgateway and 10.0.2.15

# kill tcpdump
sudo kill $(pgrep -P $TCPDUMP_PID)

# delete resources
kubectl delete -f sec-egress--mtls-originatation-from-egress-gateway.yaml
