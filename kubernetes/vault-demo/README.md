# Demo: Vault on Kubernetes

## Preparations

To build the container run following command

    cd docker
    docker build -t vault:0.9.0 .


Config file `/etc/vault/config.hcl`

    storage "file" {
      path = "/var/lib/vault"
    }

    listener "tcp" {
      tls_cert_file = "/etc/vault/vault-cert.pem"
      tls_key_file  = "/etc/vault/vault-pkey.pem"
    }
