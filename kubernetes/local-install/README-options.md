

# Optional features

## Persistent volume storage

### Install rook

[Rook](https://rook.io/) provides an easy way to self-host
[Ceph](https://ceph.com/) distributed storage on the same Kubernetes
cluster as you run your workload.  This example shows how to deploy
Rook on a cluster with at least three worker nodes:

    git clone https://github.com/rook/rook.git
    cd rook/cluster/examples/kubernetes/

    # deploy rook operator
    kubectl create -f rook-operator.yaml

    # wait until three rook-agents have started
    kubectl -n rook-system get pod --watch

    # deploy root cluster
    kubectl create -f rook-cluster.yaml

    # wait until three rook-ceph-mons and rook-ceph-osds have started
    kubectl -n rook get pod --watch

    # create storage class
    kubectl create -f rook-storageclass.yaml

See
[full instructions](https://rook.io/docs/rook/master/kubernetes.html)
on Rook web site for more information.

See instructions in [manifests/pv-test.yml](manifests/pv-test.yml) to
test the `rook-block` storage class.


### Delete rook installation

Delete deployment

    kubectl delete -f rook-storageclass.yaml
    kubectl delete -f rook-cluster.yaml
    kubectl delete -f rook-operator.yaml


Run following in each node in the cluster

    sudo rm -r /var/lib/rook/


## Install docker-registry

Add helm incubator repository and follow instructions from helm chart [page](https://kubeapps.com/charts/incubator/docker-registry)

    helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
    helm install incubator/docker-registry --set persistence.enabled=true,persistence.size=1Gi,persistence.storageClass=rook-block --version 0.2.3


Check that the pod started:

    kubectl get pods



    kubectl port-forward $POD_NAME 5000:5000


## Helm

Download helm client from
[here](https://github.com/kubernetes/helm/releases) and install it
locally.

Create service account and deploy helm into Kubernetes cluster:

    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    helm init --service-account=tiller


