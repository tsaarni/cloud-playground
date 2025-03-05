
Create virtual environment and install dependencies to it

```console
python3 -mvenv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

Create a Kind cluster and deploy Contour

```console
kind create cluster --name api-tests
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```

Use following to observe the watch behavior when HTTPproxy resources are created / modified / deleted

```console
./httpproxy.sh create test-001
./httpproxy.sh apply test-001
./httpproxy.sh delete test-001
```


List HTTPProxies

```console
./list-and-watch.py list
```

Watch HTTPProxies

```console
./list-and-watch.py watch
```

List or watch from a specific resource version

```console
./list-and-watch.py --resource-version 123 list
./list-and-watch.py --resource-version 123 watch
```

Watch will fail if the resource version is too old

```console
./list-and-watch.py --resource-version 1 watch

Error during watch: (410) -
Reason: Expired: too old resource version: 1 (262916)
```

Start watch from the latest resource version

```console
./list-and-watch.py watch
```

Use Wireshark to see the low-level HTTP REST API requests and responses e.g. while running the watch

```console
wireshark -k -i lo -o tls.keylog_file:wireshark-keys.log -Y http

# in another terminal
./list-and-watch.py --sslkeylogfile wireshark-keys.log watch
```

To clean up after testing, delete Kind cluster

```console
kind delete cluster --name api-tests
```
