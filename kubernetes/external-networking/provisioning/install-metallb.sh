#!/bin/bash -ex
#
# https://metallb.universe.tf/tutorial/layer2/
#

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: oam
      protocol: layer2
      addresses:
      - 10.10.11.100-10.10.11.200
    - name: traffic
      protocol: layer2
      addresses:
      - 10.10.12.100-10.10.12.200
EOF
