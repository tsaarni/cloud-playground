#!/bin/bash -ex
#
# Description
#
# In this demo client running outside mesh makes a request to service
# running within the mesh. The client credentials are automatically
# issued by Istio Citadel into a Kubernetes Secret, according to
# Service Account resource.
#
# Note that this aleternative is not feasible in most cases:
#  - TLS clients do not implement validation of SPIFFE certificates
#  - it depends on implementation detail on how SPIFFE certificates are distributed as of today

# create resources
kubectl apply -f sec-mixed--client-outside-mesh-accesses-service-inside-mesh-using-spiffe-cert.yaml

# make request from outside mesh to service running within mesh.
#
# Note that server certificate verification needed to be disabled because
# client expects to have hostname as SAN instead of SPIFFE certificate
kubectl -n outside-mesh exec $(kubectl -n outside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') -- ash -c "http --verify=no --cert=/run/secrets/certs/cert-chain.pem --cert-key=/run/secrets/certs/key.pem GET https://httpbin.inside-mesh.svc.cluster.local:80/status/418 </dev/null"

# delete resources
kubectl delete -f sec-mixed--client-outside-mesh-accesses-service-inside-mesh-using-spiffe-cert.yaml
