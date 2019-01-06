#!/bin/bash -ex
#
# Description
#
# In this demo a service is running inside service mesh and an
# external client accesses it using HTTPS.  Istio ingress-gateway
# terminates the external TLS connection on behalf of the service.
#
# The request is routed to the service by using both TLS SNI (server
# name indication) extension header and "Host:" HTTP header.
#

# create resources
kubectl apply -f sec-ingress--terminate-tls-in-ingress-gateway-using-sni.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# wait for envoy to be configured
sleep 1

# make a successful HTTPS request to the service via istio-ingressgateway
http --verify certs/server-root.pem https://host1.external.com/status/418

# Istio-ingressgateway is configured to require client to send server
# name with TLS SNI extension.  Attempt to make TLS connection without
# TLS SNI will fail
echo Q | openssl s_client -quiet -CAfile certs/server-root.pem -connect host1.external.com:443 || true  # ignore failed connection attempt

# Test few variants to demonstrate routing at SNI and HTTP Host header level
#   - request with "Host: host1.external.com" and TLS SNI "host2.external.com" -> TLS connection ok, HTTP request ok
#   - request with "Host: host2.external.com" and TLS SNI "host2.external.com" -> TLS connection ok, HTTP request fails
#   - request with "Host: host2.external.com" and TLS SNI "host3.external.com" -> TLS connection fails
printf "GET /status/418 HTTP/1.1\r\nConnection: close\r\nHost: host1.external.com\r\n\r\n" | openssl s_client -quiet -CAfile certs/server-root.pem -connect host1.external.com:443 -servername host2.external.com
printf "GET /status/418 HTTP/1.1\r\nConnection: close\r\nHost: host2.external.com\r\n\r\n" | openssl s_client -quiet -CAfile certs/server-root.pem -connect host2.external.com:443 -servername host2.external.com
printf "GET /status/418 HTTP/1.1\r\nConnection: close\r\nHost: host3.external.com\r\n\r\n" | openssl s_client -quiet -CAfile certs/server-root.pem -connect host3.external.com:443 -servername host3.external.com || true # ignore error

# To see what is going on TLS level you can use following command to
# capture traffic at istio-ingressgateway and open the .pcap file in
# Wireshark:
#   sudo tcpdump -w capture.pcap -A -s 0 -i any -n dst port 443 and host $(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath={.items..podIP})

# delete resources
kubectl delete -f sec-ingress--terminate-tls-in-ingress-gateway-using-sni.yaml
