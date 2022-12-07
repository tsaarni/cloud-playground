# docker build -t quay.io/tsaarni/capabilities-test:latest .
FROM alpine
RUN apk add --update-cache libcap netcat-openbsd iputils && \
    cp -a /usr/bin/nc /usr/bin/nc-with-caps && \
    cp -a /bin/ping /usr/bin/ping-with-caps && \
    setcap 'cap_net_bind_service=+ep' /usr/bin/nc-with-caps && \
    setcap 'cap_net_raw=+ep' /usr/bin/ping-with-caps
CMD /bin/sh -c "grep Cap /proc/1/status && capsh --print && sleep 99999999"
