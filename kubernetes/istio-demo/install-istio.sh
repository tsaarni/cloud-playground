#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf

curl -L -s https://github.com/istio/istio/releases/download/1.0.5/istio-1.0.5-linux.tar.gz -o istio.tar.gz
tar zxf istio.tar.gz
rm istio.tar.gz
cd istio*

cp -a bin/istioctl /usr/local/bin/

helm install install/kubernetes/helm/istio --name istio --namespace istio-system -f /vagrant/configs/helm-istio-values.yaml
