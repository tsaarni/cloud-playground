#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf

# install minikube hostpath storage provisioner for persistent volumes
#    - Note: the storage provisioner uses /tmp/hostpath-provisioner/ 
#      directory in the VM to provide persistent volume storage.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/minikube/master/deploy/addons/storage-provisioner/storage-provisioner.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/minikube/master/deploy/addons/storageclass/storageclass.yaml


# install helm
curl -s https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

# create service account and role-binding for helm
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: helm
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
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

# install tiller
helm init --wait --service-account helm
