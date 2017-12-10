
FROM alpine:3.7

RUN apk --no-cache add --virtual build-dependencies ca-certificates curl unzip libcap && \
    curl -s https://releases.hashicorp.com/vault/0.9.0/vault_0.9.0_linux_amd64.zip -o vault.zip && \
    unzip vault.zip && \
    rm vault.zip && \
    mv vault /usr/bin/vault && \
    setcap cap_ipc_lock=+ep /usr/bin/vault && \
    apk del build-dependencies

CMD ["/usr/bin/vault", "server", "-config=/etc/vault/"]
