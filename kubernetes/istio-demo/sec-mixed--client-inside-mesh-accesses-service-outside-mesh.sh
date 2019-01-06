#!/bin/bash -ex
#
# Description
#
# This demonstrates a mixed use case: client is deployed within
# service mesh but it calls a service located outside of the service
# mesh.
#
# There are two services outside the mesh: one exposing HTTPS interface
# and another exposing HTTP interface.
#
#
# Details about TLS client
#
# Note that client pod within mesh must implement TLS itself
# currently.
#
# Although Envoy would be capable of implementing TLS on behalf of the
# client pod, it is not practical currently since there is no
# convenient way to inject client credentials to all sidecars.
#
# There are plans for at least for egress gateways (for external TLS
# connectivity) to implement TLS on behalf of client application
#   - https://github.com/istio/istio/issues/8541
#   - https://github.com/istio/istio/issues/9659
#


# Create resources
# Note that server and client credentials are provisioned here since they required by the services.
kubectl apply -f sec-mixed--client-inside-mesh-accesses-service-outside-mesh.yaml && \
kubectl -n outside-mesh create secret generic httpbin-certs --from-file=certs/httpbin.pem --from-file=certs/httpbin-key.pem --from-file=certs/client-root.pem && \
kubectl -n inside-mesh  create secret generic client-certs --from-file=certs/client.pem --from-file=certs/client-key.pem --from-file=certs/server-root.pem

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=client
kubectl -n outside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# use client pod inside the mesh to call HTTPS service outside mesh
kubectl -n inside-mesh exec -it $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- \
  http --verify=/run/secrets/certs/server-root.pem \
       --cert=/run/secrets/certs/client.pem \
       --cert-key=/run/secrets/certs/client-key.pem \
       https://httpbin.outside-mesh/status/418

# use client pod inside the mesh to call HTTP service outside mesh
kubectl -n inside-mesh exec -it $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- \
  http http://httpbin-notls.outside-mesh/status/418

# Delete resources
kubectl delete -f sec-mixed--client-inside-mesh-accesses-service-outside-mesh.yaml
