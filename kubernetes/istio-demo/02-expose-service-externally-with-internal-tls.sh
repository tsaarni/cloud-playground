#!/bin/bash -ex
#
# Description:
#
# Run a service inside service mesh and access it using TLS which is
# terminated at Istio ingress gateway.  The connection between gateway
# and pod is also protected by TLS.
#

# create resources
kubectl apply -f manifests/02-expose-service-externally-with-internal-tls.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# wait for envoy to be configured
sleep 1

# put tcpdump to background to capture traffic from httpbin pod
sudo tcpdump -vvvv -s 0 -A -i any -n src port 80 and host $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}) &
TCPDUMP_PID=$!

# make request and see that you cannot see teapot also in tcpdump output (traffic is encrypted)
http --verify certs/server-root.pem https://host1.external.com/status/418 || true  # ignore error from httpie

# kill tcpdump
sudo kill $(pgrep -P $TCPDUMP_PID)

# delete resources
kubectl delete -f manifests/02-expose-service-externally-with-internal-tls.yaml
