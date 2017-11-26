FROM alpine:3.6

WORKDIR /tmp

RUN apk --no-cache add ca-certificates curl unzip && \
    curl -s https://releases.hashicorp.com/vault/0.9.0/vault_0.9.0_linux_amd64.zip -o vault.zip && \
    unzip vault.zip


FROM scratch

COPY --from=0 /tmp/vault /vault
CMD ["/vault", "server", "-config=/etc/vault/"]
