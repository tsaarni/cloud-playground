#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf

# install storage provisioner
#  - https://github.com/rancher/local-path-provisioner
mkdir -p --mode=750 /opt/local-path-provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


# install helm
#  - https://github.com/helm/helm/releases
curl -L -s https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz -o helm.tar.gz
tar zxf helm.tar.gz
cp -a linux-amd64/helm /usr/local/bin/helm

# create service account and role-binding for helm
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: helm
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: helm
    namespace: kube-system
EOF

# install tiller,
# bind only to localhost in order not to expose GRPC endpoint within cluster network
helm init --wait --service-account helm --override spec.template.spec.containers[0].args='{--listen=localhost:44134}'

# add bash completions for vagrant users
echo "source <(helm completion bash)" >> ~vagrant/.bashrc
