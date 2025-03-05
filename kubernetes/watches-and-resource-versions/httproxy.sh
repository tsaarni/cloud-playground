#!/bin/sh

action=$1
num=$2

cat <<EOF | kubectl $action -f -
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
    name: echoserver-$num
    annotations:
        date: "$(date)"
spec:
    virtualhost:
        fqdn: echoserver-$num.127-0-0-101.nip.io
    routes:
        - services:
            - name: echoserver-$num
              port: 80
EOF
