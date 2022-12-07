
## General

```
kubectl apply -f demo.yaml
```

Check the capabilities by running

```
kubectl logs <podname>
```

Test the `CAP_NET_BIND_SERVICE` capability by trying to bind to privileged port

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
