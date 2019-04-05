# deploy the TCP echo service and expose it using Contour TCP proxying
kubectl apply -f demo-tcpproxy.yaml

# Connect to Contour using TLS and send test message
# The s_client will indicate tcpecho.local as the target FQDN.
# TCP echo service echoes the Hello world back
(echo "Hello world!" && sleep 1) | openssl s_client -connect tcpecho.local:443 -servername tcpecho.local -CAfile certs/server-root.pem

# HTTPS connection will fail since traffic will be forwarded to the
# TCP echo server, which just echoes the GET request and confuses the HTTP client
http -v --verify=certs/server-root.pem https://tcpecho.local
