
# Client-go with custom TLS config

run Wireshark with the following command to enable TLS decryption using the keylog file:

```console
$ wireshark -i lo -k -o tls.keylog_file:keylog.txt
```

and then run the example

```console
$ go run main.go
```
