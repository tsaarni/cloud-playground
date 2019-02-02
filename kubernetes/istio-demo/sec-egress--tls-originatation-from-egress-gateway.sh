#!/bin/bash -ex
#
# Description
#
# This script demonstrates TLS origination towards cluster external
# service using egress gateway
#

# create resources
kubectl apply -f sec-egress--tls-originatation-from-egress-gateway.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=client

# check that the outbound connection is going through egress gateway to httpbin.org
# by capturing the traffic from client envoy sidecar
sudo tcpdump -vvvv -s 0 -A -i any dst port 443 and src host $(kubectl -n istio-system get pod -l istio=egressgateway -o jsonpath={.items..podIP}) &
TCPDUMP_PID=$!

# use client pod inside the mesh to call HTTPS service external to the cluster
kubectl -n inside-mesh exec -it $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- \
        ash -c "http http://httpbin.org/status/418 </dev/null"

# observe the tcpdump output
# it shows traffic between gateway and nnnn.amazonaws.com

# kill tcpdump
sudo kill $(pgrep -P $TCPDUMP_PID)

# delete resources
kubectl delete -f sec-egress--tls-originatation-from-egress-gateway.yaml
