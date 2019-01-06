#!/bin/bash -ex
#
# Description
#
# Istio does not protect pod-to-pod traffic with TLS by default.
# Demonstrate this by capturing traffic between ingress gateway and
# service.
#
#
# Enabling TLS globally
#
# TLS can be enabled globally by providing following parameter during
# Istio helm installation: --set global.mtls.enabled=true or by
# defining global MeshPolicy resource with name "default".  See other
# demos as a reference for the latter.
#

# create resources
kubectl apply -f sec-explore--istio-proxy-no-tls-by-default.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=client


# Check that the internal communication is NOT encrypted since we have
# not enabled Istio TLS policy.  First put tcpdump to background to
# capture traffic from httpbin pod to istio-ingressgateway
sudo tcpdump -s 0 -A -i any -n port 80 and host $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}) &
TCPDUMP_PID=$!

# use client pod to call HTTP service without Istio TLS policy.
# Note that the output from tcpdump is in cleartext
kubectl -n inside-mesh exec $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- ash -c "http GET http://httpbin/status/418 </dev/null >/dev/null"

# use client pod to call HTTP service with Istio TLS policy
# Note that the output from tcpdump is encrypted
kubectl -n inside-mesh exec $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- ash -c "http GET http://httpbin-protected/status/418 </dev/null >/dev/null"

# Note that tcpdump displays the payload twice because it captures the
# packets twice: once entering the linux bridge and once exiting the
# bridge.

# kill tcpdump
sudo kill $(pgrep -P $TCPDUMP_PID)

# delete resources
kubectl delete -f sec-explore--istio-proxy-no-tls-by-default.yaml
