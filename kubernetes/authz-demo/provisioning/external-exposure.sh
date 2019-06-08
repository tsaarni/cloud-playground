#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf

# Install MetalLB and configure it in layer2 mode
#
#  - https://github.com/danderson/metallb/releases
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
    - name: default
      protocol: layer2
      addresses:
      - 192.168.195.100-192.168.195.250
EOF


# install avahi mdns daemon for resolving DNS for public addresses
apt-get install -y avahi-daemon

# install external-dns fork that writes hosts file for avahi
#
#   - https://github.com/tsaarni/k8s-external-mdns
#
kubectl apply -f https://raw.githubusercontent.com/tsaarni/k8s-external-mdns/master/external-dns-with-avahi-mdns.yaml
