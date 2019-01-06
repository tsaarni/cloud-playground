#!/bin/bash -ex
#
# Description
#
# In this demo two clients are deployed:
#  - client1 is using the default service account, not bound to any RBAC rule
#  - client2 is provisioned with a service account bound to RBAC rule
# RBAC rule gives access to httpbin REST API endpoints
#
# See also https://istio.io/blog/2018/istio-authorization/
#


# create resources
kubectl apply -f sec-auth--rbac-on-service-level.yaml

# wait until deployed
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=httpbin
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=client1
kubectl -n inside-mesh wait deployment --timeout=60s --for condition=available -l app=client2

# wait for envoys to be configured
sleep 1

# sending request from client1 will fail
# since it uses the default service account which has not been granted access to the service
kubectl -n inside-mesh exec $(kubectl -n inside-mesh get pod -l app=client1 -o jsonpath='{.items[0].metadata.name}') --container=client -- ash -c "http GET http://httpbin/status/418 </dev/null"

# sending request from client2 will succeed
# since it uses the `myserviceaccount` which has been bound to RBAC role
kubectl -n inside-mesh exec $(kubectl -n inside-mesh get pod -l app=client2 -o jsonpath='{.items[0].metadata.name}') --container=client -- ash -c "http GET http://httpbin/status/418 </dev/null"


# delete resources
kubectl delete -f sec-auth--rbac-on-service-level.yaml
