#!/bin/bash -ex
#
# Install kubernetes and docker
#
# References
# * https://kubernetes.io/docs/setup/independent/install-kubeadm/
# * https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
#

# configure repos
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
echo deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable > /etc/apt/sources.list.d/docker.list

curl -fsSl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update

# install dependencies
apt-get install -y conntrack

# enable remote access
mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
EOF

# install docker
docker_version=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
apt-get install -y docker-ce=$docker_version

# install kubernetes
kubernetes_version=$(apt-cache madison kubelet | grep 1.12 | head -1 | awk '{print $3}')
kubernetes_cni_version=$(apt-cache madison kubernetes-cni | grep 0.6 | head -1 | awk '{print $3}')
apt-get install -y kubeadm=$kubernetes_version kubelet=$kubernetes_version kubernetes-cni=$kubernetes_cni_version

# intialize kubernetes master
#   --apiserver-cert-extra-sans is needed since we want to use kubectl with virtualbox NAT port forward
#   --pod-network-cidr=192.168.0.0/16 is needed for calico
kubeadm init --apiserver-cert-extra-sans 127.0.0.1 --pod-network-cidr=192.168.0.0/16

# install CNI networking plugin
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

# allow scheduling of pods on master node
kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-

# make kubernetes admin.conf available for host machine and for vagrant-user
cp /etc/kubernetes/admin.conf /vagrant
mkdir ~vagrant/.kube
cp /etc/kubernetes/admin.conf ~vagrant/.kube/config
chown -R vagrant:vagrant ~vagrant/.kube

# allow vagrant-user to run docker without sudo
usermod -a -G docker vagrant

# replace internal kubernetes api server address with localhost, so it can be accessed via virtualbox port forward
sed -i 's!server: .*!server: https://127.0.0.1:6443!g' /vagrant/admin.conf

# wait for the node to come up
set +x  # disable bash trace
while true; do
    status=$(kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes -o jsonpath='{.items[*].status.conditions[?($.status == "True")].status}')
    if [[ $status == "True" ]]; then
        break
    fi
    echo "Running 'kubectl get nodes' and waiting for the nodes to come up..."
    sleep 3
done
set -x
