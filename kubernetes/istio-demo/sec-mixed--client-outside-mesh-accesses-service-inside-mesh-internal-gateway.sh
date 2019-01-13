#!/bin/bash -ex
#
# Description
#
# In this demo client running outside mesh makes a request to a
# service running within the mesh.  The request is routed through
# istio gateway which is dedicated only for this purpose, and which is
# exposed using cluster IP to prevent unintented exposure of services
# to outside the cluster.
#
# Note that the istio-internal-ingressgateway is deployed already
# during helm install, by definitions in values.yaml, see file
# configs/helm-istio-values.yaml.  The server certificates are also
# provisioned during deployment in script provisioning/prepare-demo.sh
#


# create resourses
kubectl apply -f sec-mixed--client-outside-mesh-accesses-service-inside-mesh-internal-gateway.yaml && \
kubectl -n outside-mesh create secret generic client-certs --from-file=certs/client.pem --from-file=certs/client-key.pem --from-file=certs/server-root.pem

# wait until deployed
kubectl -n outside-mesh wait deployment --timeout=60s --for condition=available -l app=client
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin

# wait for envoy to be configured
sleep 1

# see that the internal ingressgateway is exposed with cluster IP, and therefore it is not visible outside of the cluster
kubectl -n istio-system get service istio-internal-ingressgateway

# use client pod oustide the mesh to call the internal istio gateway
kubectl -n outside-mesh exec -it $(kubectl -n outside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') -- \
  http --verify=/run/secrets/certs/server-root.pem \
       https://istio-internal-ingressgateway.istio-system/status/418

# delete resources
kubectl delete -f sec-mixed--client-outside-mesh-accesses-service-inside-mesh-internal-gateway.yaml
