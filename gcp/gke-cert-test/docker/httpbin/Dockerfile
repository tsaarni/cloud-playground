FROM alpine:3.10
RUN apk --update add python3 && \
    apk add --virtual build-dependencies python3-dev build-base libffi-dev && \
    pip3 install --no-cache-dir httpbin gunicorn && \
    apk del build-dependencies && \
    rm -rf /root/.cache /var/cache/apk/*
EXPOSE 80
CMD ["gunicorn", "-b", "0.0.0.0:80", "--access-logfile", "-", "httpbin:app"]
