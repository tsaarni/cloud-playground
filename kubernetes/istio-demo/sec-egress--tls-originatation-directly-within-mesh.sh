#!/bin/bash -ex
#
# Description
#
# This script demonstrates TLS origination in sidecar towards
# cluster external service without going through egress gateway
#

# create resources
kubectl apply -f sec-egress--tls-originatation-directly-within-mesh.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=client

# check that the outbound connection is going directly from client to httpbin.org
# by capturing the traffic from client envoy sidecar
sudo tcpdump -vvvv -s 0 -A -i any port 443 and host $(kubectl -n inside-mesh get pod -l app=client -o jsonpath={.items..podIP}) &
TCPDUMP_PID=$!

# use client pod inside the mesh to call HTTPS service external to the cluster
kubectl -n inside-mesh exec -it $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- \
        ash -c "http http://httpbin.org/status/418 </dev/null"

# observe the tcpdump output as it shows direct traffic between client and nnnn.amazonaws.com

# kill tcpdump
sudo kill $(pgrep -P $TCPDUMP_PID)

# delete resources
kubectl delete -f sec-egress--tls-originatation-directly-within-mesh.yaml
