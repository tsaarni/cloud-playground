
Create virtual environment and install dependencies to it

```console
python3 -mvenv .venv   # create new virtual environment
. .venv/bin/activate
pip install -r requirements.txt
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

```
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

In another terminal, create / modify /delete HTTPProxy and observe the watch output

```console
./httproxy.sh create test-001
./httproxy.sh apply test-001
./httproxy.sh delete test-001
```

Use Wireshark to see the REST API calls while running the watch

```console
wireshark -k -i lo -o tls.keylog_file:wireshark-keys.log -Y http

# in another terminal
./list-and-watch.py --sslkeylogfile wireshark-keys.log watch
```
