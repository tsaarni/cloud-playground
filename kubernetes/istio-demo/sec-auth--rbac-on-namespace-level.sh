#!/bin/bash -ex
#
# Description
#
# In this demo we deploy
#  - sshd in frontend namespace
#  - two instances of httpbin service in the backend namespace
#  - client in backend namespace
# and demonstrate RBAC rules to limit access to the services within backend.
#

# create resources
kubectl apply -f sec-auth--rbac-on-namespace-level.yaml

# wait until deployed
kubectl -n frontend wait deployment --timeout=60s --for condition=available -l app=sshd
kubectl -n backend wait deployment --timeout=60s --for condition=available -l app=httpbin-restricted
kubectl -n backend wait deployment --timeout=60s --for condition=available -l app=httpbin-blocked
kubectl -n backend wait deployment --timeout=60s --for condition=available -l app=client

# wait for envoy to be configured
sleep 1

# make requests from frontend namespace to backend
# make following requests from sshd pod to httpbin pod
#   httpbin-restricted.backend/status/418 -> allowed by RBAC path rule
#   httpbin-restricted.backend/headers    -> allowed by RBAC path rule
#   httpbin-restricted.backend/user-agent -> blocked by RBAC path rule
#   httpbin-blocked.backend/status/417    -> blocked by RBAC constraint rule
sshpass -p password ssh sshuser@host1.external.com -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "http GET http://httpbin-restricted.backend/status/418 </dev/null"
sshpass -p password ssh sshuser@host1.external.com -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "http GET http://httpbin-restricted.backend/headers </dev/null"
sshpass -p password ssh sshuser@host1.external.com -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "http GET http://httpbin-restricted.backend/user-agent </dev/null"
sshpass -p password ssh sshuser@host1.external.com -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "http GET http://httpbin-blocked.backend/status/418 </dev/null"

# make request within backend namespace
#   client -> httpbin-restricted  blocked by RBAC constraint rule
#   client -> httpbin-blocked     blocked by RBAC constraint rule
kubectl -n backend exec $(kubectl -n backend get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- ash -c "http GET http://httpbin-restricted/status/418 </dev/null"
kubectl -n backend exec $(kubectl -n backend get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container=client -- ash -c "http GET http://httpbin-blocked/status/418 </dev/null"

# note that authorization is possible due to default istio
# certificates having namespace within the SAN
#
#  - spiffe://cluster.local/ns/frontend/sa/default
#  - spiffe://cluster.local/ns/backend/sa/default
#
# for other properties to authorization decision see Properties here
# https://istio.io/docs/reference/config/authorization/constraints-and-properties/#properties
kubectl -n frontend get secret istio.default -o jsonpath="{..cert-chain\.pem}" | base64 -d | openssl x509 -text -noout
kubectl -n backend get secret istio.default -o jsonpath="{..cert-chain\.pem}" | base64 -d | openssl x509 -text -noout


# delete resources
kubectl delete -f sec-auth--rbac-on-namespace-level.yaml
