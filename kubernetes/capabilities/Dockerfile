# docker build -t quay.io/tsaarni/capabilities-test:latest .
FROM alpine
RUN apk add --update-cache libcap netcat-openbsd && \
    cp -a /usr/bin/nc /usr/bin/nc-with-caps && \
    setcap 'cap_net_bind_service=+ep' /usr/bin/nc-with-caps
