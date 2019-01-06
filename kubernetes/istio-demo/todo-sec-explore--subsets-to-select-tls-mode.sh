#!/bin/bash -ex
#
# Description
#
# TODO:  THIS DID NOT WORK!!!
#
# Instead of using namespace to select which service is within our
# outside mesh, use "subsets" DestinationRule with label selector
# instead, and add label to each pod to drive the selector.
#

# create resources
kubectl apply -f todo-sec-explore--subsets-to-select-tls-mode.yaml

# wait until deployed
kubectl -n demo wait deployment --timeout=60s --for condition=available -l app=httpbin-without-proxy
kubectl -n demo wait deployment --timeout=60s --for condition=available -l app=httpbin-with-proxy
kubectl -n demo wait deployment --timeout=60s --for condition=available -l app=client

# check that
#  - "httpbin-with-proxy*" shows 2/2     (httpbin container + istio proxy)
#  - "httpbin-without-proxy*" shows 1/1  (httbin container only)
kubectl -n demo get pods

# use client pod to make requests to both services
kubectl -n demo exec $(kubectl -n demo get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container client -- ash -c "http GET http://httpbin-without-proxy/status/418 </dev/null"
kubectl -n demo exec $(kubectl -n demo get pod -l app=client -o jsonpath='{.items[0].metadata.name}') --container client -- ash -c "http GET http://httpbin-with-proxy/status/418 </dev/null"

# delete resources
kubectl delete -f todo-sec-explore--subsets-to-select-tls-mode.yaml
