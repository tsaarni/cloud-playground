FROM alpine:3.8
RUN apk --update add openssh-server && \
    adduser -D sshuser && \
    echo sshuser:password | chpasswd
ADD entrypoint.sh /
ENTRYPOINT /entrypoint.sh
