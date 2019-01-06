#!/bin/bash -ex
#
# Description
#
# In this demo a service is running within the service mesh with
# "permissive" mode, meaning that clients outside the mesh can access
# the service in HTTP.  Clients within the mesh will still
# automatically be protected with TLS:
#
#
# To see the network traffic and prove the above, run following on
# another terminal:
#
#   sudo tcpdump -s 0 -A -i any -n port 80 and host $(kubectl -n inside-mesh get pod -l app=httpbin -o jsonpath={.items..podIP})
#

# create resources
kubectl apply -f sec-mixed--client-outside-mesh-accesses-service-inside-mesh-no-tls.yaml

# client from outside service mesh will access the service in cleartext
kubectl -n outside-mesh exec $(kubectl -n outside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') -- ash -c "http GET http://httpbin.inside-mesh/status/418 </dev/null"

# Second client is running within the service mesh. When it accesses
# the service, the traffic will be automatically protected by TLS.
kubectl -n inside-mesh exec $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- ash -c "http GET http://httpbin/status/418 </dev/null"

# delete resources
kubectl delete -f sec-mixed--client-outside-mesh-accesses-service-inside-mesh-no-tls.yaml
