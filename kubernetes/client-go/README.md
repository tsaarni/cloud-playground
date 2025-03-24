
# Client-go with custom TLS config

The code in `main.go` customizes TLS settings by directly modifying the [tls.Config](https://pkg.go.dev/crypto/tls#Config) for the transport.
In the example, it configures TLS ciphers and enables key logging for Wireshark.

To run the example:

Run Wireshark with the following command to enable TLS decryption using the keylog file:

```console
$ wireshark -i lo -k -o tls.keylog_file:keylog.txt
```

and then run the example

```console
$ go run main.go
```
