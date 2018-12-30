#!/bin/bash -ex
#
# Description
#
# Run a service inside service mesh and access it using TLS which is
# terminated at Istio ingress gateway.  The connection between gateway
# and pod is not protected by TLS.
#

# create resources
kubectl apply -f manifests/01-expose-service-externally-with-tls.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# check that httpbin is running and that there is sidecar (status shows READY 2/2)
kubectl -n inside-mesh get pods

# wait for envoy to be configured
sleep 1

# make request via the istio ingress gateway, you should see an ASCII-art of a teapot
http --verify certs/server-root.pem https://host1.external.com/status/418

# see that the certificate really has the DNS SAN entry for host1.external.com
echo Q | openssl s_client -connect host1.external.com:443 -servername host1.external.com 2>/dev/null | openssl x509 -text -noout

# put tcpdump to background to capture traffic from httpbin pod
sudo tcpdump -vvvv -s 0 -A -i any -n src port 80 and host $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP}) &
TCPDUMP_PID=$!

# make another request and see that you see teapot also in tcpdump output (cleartext since no TLS)
http --verify certs/server-root.pem https://host1.external.com/status/418

# kill tcpdump
sudo kill $(pgrep -P $TCPDUMP_PID)

# request sent directly to the pod IP will work aswell
http http://$(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP})/status/418

# request sent via Service's cluster IP will work
http http://$(kubectl -n inside-mesh get service -l app=httpbin -o jsonpath={.items..clusterIP})/status/418

# delete resources
kubectl delete -f manifests/01-expose-service-externally-with-tls.yaml
