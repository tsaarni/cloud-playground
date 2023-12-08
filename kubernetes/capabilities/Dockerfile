# docker build -t quay.io/tsaarni/capabilities-test:latest .
FROM alpine AS build
RUN apk add --update-cache gcc musl-dev libcap-dev
COPY captest.c /tmp/captest.c
RUN gcc -Wall -o /tmp/captest /tmp/captest.c -lcap


FROM alpine
RUN apk add --update-cache libcap netcat-openbsd iputils && \
    cp -a /usr/bin/nc /usr/bin/nc-with-caps && \
    cp -a /bin/ping /usr/bin/ping-with-caps && \
    setcap 'cap_net_bind_service=+ep' /usr/bin/nc-with-caps && \
    setcap 'cap_net_raw=+ep' /usr/bin/ping-with-caps
COPY --from=build /tmp/captest /captest
COPY print-capabilities.sh /
CMD /bin/sh -c "/print-capabilities.sh && sleep 99999999"
