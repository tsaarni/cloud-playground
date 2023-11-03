
## Linux capabilities demo

First build the image (also available in quay.io)

```
docker build -t quay.io/tsaarni/capabilities-test:latest .
```

To test on Kind cluster, first create the cluster and preload the image

```
kind create cluster
kind load docker-image quay.io/tsaarni/capabilities-test:latest
```

Then deploy the demo pods by running

```
kubectl apply -f demo.yaml
```

The container will print capabilities at start.
To check the capabilities run

```
kubectl logs <podname>
```

Test the `CAP_NET_BIND_SERVICE` capability by trying to bind to privileged port.
First exec into the pod `kubectl exec -it <podname>` and then run

```
nc -l localhost 80            # netcat without file capabilities set
nc-with-caps -l localhost 80  # netcat with cap_net_bind_service=+ep
```

## OpenShift

https://docs.okd.io/latest/authentication/managing-security-context-constraints.htm
https://medium.com/@tamber/openshift-infrastructure-permissions-best-practice-scc-security-context-constraints-c24e961e2fcc


```
oc login -u kubeadmin https://api.crc.testing:6443
oc login -u developer https://api.crc.testing:6443
```

```
oc new-project test

# with restricted policy
sed -e '/remove when running with restricted scc on openshift/d' < demo.yaml | oc apply -f -

oc apply -f demo.yaml
oc delete -f demo.yaml

# as admin
oc apply -f scc-demo-policy.yaml
oc adm policy add-scc-to-user scc-demo -z scc-demo-service-account

# as user
oc apply -f scc-demo-workload.yaml
oc logs scc-demo-non-root-add-caps
oc logs scc-demo-root-add-caps

# as admin
oc adm policy remove-scc-from-user scc-demo -z scc-demo-service-account
oc delete -f scc-demo-policy.yaml

```
