kubectl apply -f demo-tls-sni.yaml

# Connect to Contour using TLS and send test message.
# The s_client will indicate tcpecho.local as the target FQDN.
# TCP echo service echoes the Hello world back
(echo "Hello world!" && sleep 1) | openssl s_client -connect tcpecho.local:443 -servername tcpecho.local -CAfile certs/server-root.pem

# Connect with TLS SNI set to different target FQDN
# httpbin service responds to the request
http -v --verify=certs/server-root.pem https://httpbin.local/status/418

# Connecting with HTTP will work also
# By default Contour will redirect to HTTPS endpoint, but in manifest we have
# allowed cleartext HTTP connections
http -v http://httpbin.local/status/418

# Connecting with different hostname will NOT work.  Contour discards the
# requested since the HTTP Host header in the request does not match with
# any of the route rules
http -v http://tcpecho.local/status/418
