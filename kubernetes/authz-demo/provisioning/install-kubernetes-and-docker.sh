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

# enable docker remote access outside the VM
mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
EOF

# install docker
docker_version=$(apt-cache madison docker-ce | grep 18.09 | head -1 | awk '{print $3}')
apt-get install -y docker-ce=$docker_version

# install kubernetes
kubernetes_version=1.14
kubernetes_deb_version=$(apt-cache madison kubelet | grep $kubernetes_version | head -1 | awk '{print $3}')
apt-get install -y kubeadm=$kubernetes_deb_version kubelet=$kubernetes_deb_version kubectl=$kubernetes_deb_version

# intialize kubernetes master
#   Note: use command "kubeadm config print-default" to print all config file parameters
kubeadm init --config /vagrant/configs/kubeadm-config.yaml

# install CNI networking plugin
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

# since we only have one node, allow scheduling of pods on master node
kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-

# make kubernetes admin.conf available for host machine and for vagrant-user
cp /etc/kubernetes/admin.conf /vagrant
mkdir ~vagrant/.kube
cp /etc/kubernetes/admin.conf ~vagrant/.kube/config
chown -R vagrant:vagrant ~vagrant/.kube

# add bash completions for vagrant user
echo "source <(kubectl completion bash)" >> ~vagrant/.bashrc

# add vagrant to docker group to allow running docker without sudo
usermod -a -G docker vagrant

# replace internal kubernetes api server address with localhost, so it can be accessed also outside the VM via virtualbox port forward
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
