#!/bin/bash -ex




kubectl apply -f expose-with-traefik-ingress.yaml

kubectl -n demo create secret tls traefik-ingress-tls-cert --cert=certs/ingress.pem --key=certs/ingress-key.pem
kubectl -n demo create secret generic traefik-ingress-client-cert --from-file certs/client-root.pem


# vagrant ssh-config > ssh-config
# ssh -F ssh-config oam -L 8080:10.10.11.100:8080

http --verify /vagrant/certs/server-root.pem https://10.10.12.100.xip.io/httpbin/status/418


echo Q | openssl s_client -connect 10.10.12.100.xip.io:443 -servername 10.10.12.100.xip.io | openssl x509 -text -noout




http --verify /vagrant/certs/server-root.pem --cert certs/client.pem --cert-key certs/client-key.pem https://10.10.12.100.xip.io/httpbin/headers


kubectl delete -f expose-with-traefik-ingress.yaml
