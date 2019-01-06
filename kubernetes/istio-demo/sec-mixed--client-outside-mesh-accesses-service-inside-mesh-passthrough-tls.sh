#!/bin/bash -ex
#
# Description
#
# In this demo there are two clients, one within the service mesh and
# another outside the mesh. Service is deployed within the mesh and
# implements TLS itself. Although service pod has proxy, it is
# configured to bypass TLS.
#
#

# create resources
kubectl apply -f sec-mixed--client-outside-mesh-accesses-service-inside-mesh-passthrough-tls.yaml && \
kubectl -n inside-mesh create secret generic httpbin-certs --from-file=certs/httpbin.pem --from-file=certs/httpbin-key.pem --from-file=certs/client-root.pem && \
kubectl -n inside-mesh create secret generic client-certs --from-file=certs/client.pem --from-file=certs/client-key.pem --from-file=certs/server-root.pem && \
kubectl -n outside-mesh create secret generic client-certs --from-file=certs/client.pem --from-file=certs/client-key.pem --from-file=certs/server-root.pem


# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin
kubectl -n outside-mesh wait deployment --timeout=60s --for condition=available -l app=client

# use client pod oustside the mesh to call HTTPS service inside mesh
kubectl -n outside-mesh exec -it $(kubectl -n outside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') -- \
  http --verify=/run/secrets/certs/server-root.pem \
       --cert=/run/secrets/certs/client.pem \
       --cert-key=/run/secrets/certs/client-key.pem \
       https://httpbin.inside-mesh/status/418

# use client pod oustside the mesh to call HTTPS service inside mesh
kubectl -n outside-mesh exec -it $(kubectl -n outside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') -- ash -c \
  "echo Q | openssl s_client -CAfile /run/secrets/certs/server-root.pem -cert /run/secrets/certs/client.pem -key /run/secrets/certs/client-key.pem -connect httpbin.inside-mesh.svc.cluster.local:443 -servername httpbin.inside-mesh.svc.cluster.local | openssl x509 -text -noout"

kubectl -n inside-mesh exec -it $(kubectl -n inside-mesh get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container client -- ash -c \
  "echo Q | openssl s_client -CAfile /run/secrets/certs/server-root.pem -cert /run/secrets/certs/client.pem -key /run/secrets/certs/client-key.pem -connect httpbin.inside-mesh.svc.cluster.local:443 -servername httpbin.inside-mesh.svc.cluster.local | openssl x509 -text -noout"


# delete resources
kubectl delete -f sec-mixed--client-outside-mesh-accesses-service-inside-mesh-passthrough-tls.yaml
