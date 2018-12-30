#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf

#ISTIO_RELEASE=https://github.com/istio/istio/releases/download/1.1.0-snapshot.3/istio-1.1.0-snapshot.3-linux.tar.gz
ISTIO_RELEASE=https://github.com/istio/istio/releases/download/1.0.5/istio-1.0.5-linux.tar.gz

curl -L -s $ISTIO_RELEASE -o istio.tar.gz
tar zxf istio.tar.gz -C /tmp
rm istio.tar.gz
cd /tmp/istio*

cp -a bin/istioctl /usr/local/bin/

helm install install/kubernetes/helm/istio --name istio --namespace istio-system -f /vagrant/configs/helm-istio-values.yaml


# or upgrade existing install
# helm upgrade istio install/kubernetes/helm/istio -f /vagrant/configs/helm-istio-values.yaml --install
