
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



