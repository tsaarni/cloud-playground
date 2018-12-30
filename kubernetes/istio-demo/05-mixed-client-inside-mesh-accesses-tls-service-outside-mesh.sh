#!/bin/bash -ex
#
# Description
#
# Demonstrate mixed use case where client within service mesh calls a service
# located outside of the service mesh.
#
# There is two services outside the mesh: one exposing HTTPS interface
# and another exposing HTTP interface.
#

# Create resources
kubectl apply -f manifests/05-mixed-client-inside-mesh-accesses-tls-service-outside-mesh.yaml

# Provision server and client certificates
#
# note: this needs to be done before waiting (next command) because
# the existence of the secret is precondition for successful
# deployment due to volume mounts
kubectl -n outside-mesh create secret generic httpbin-certs --from-file=certs/httpbin.pem --from-file=certs/httpbin-key.pem --from-file=certs/client-root.pem
kubectl -n inside-mesh  create secret generic client-certs --from-file=certs/client.pem --from-file=certs/client-key.pem --from-file=certs/server-root.pem

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=client
kubectl -n outside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin



# Call HTTPS service outside mesh.
#
# Note: client within mesh must implement TLS client itself currently.
# Although Envoy would be capable of implementing TLS client, and
# DestinationRule can be configured with trafficPolicy with tls mode
# MUTUAL, it is not practical to inject the files on all sidecars and
# gateways.
#
# In future there will be solution, at least for egress gateways to
# implement TLS client on behalf of application, for external
# connectivity
# - https://github.com/istio/istio/issues/8541
# - https://github.com/istio/istio/issues/9659

kubectl -n inside-mesh exec -it $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- \
  http --verify=/run/secrets/certs/server-root.pem \
       --cert=/run/secrets/certs/client.pem \
       --cert-key=/run/secrets/certs/client-key.pem \
       https://httpbin.outside-mesh/headers

# Call HTTP service outside mesh
kubectl -n inside-mesh exec -it $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- \
  http http://httpbin-notls.outside-mesh/headers

# Delete resources
kubectl delete -f manifests/05-mixed-client-inside-mesh-accesses-tls-service-outside-mesh.yaml
