listener "tcp" {
    address = "0.0.0.0:8200"
    tls_cert_file = "/var/run/secrets/vault-cert/vault.pem"
    tls_key_file = "/var/run/secrets/vault-cert/vault-key.pem"
}

storage "file" {
    path = "/vault/file"
}
