
Using Kargo for setting up kubernetes cluster https://github.com/kubernetes-incubator/kargo


Install python to all nodes

    ansible all -u ubuntu --become -i inventory.cfg -m raw -a 'apt-get update && apt-get install -y python'


Create inventory file `inventory.cfg` where `ansible_host` is the
public address and `ip` is the private address.

    [all]
    node1 	 ansible_host=54.154.76.155 ip=172.31.30.164
    node2 	 ansible_host=54.154.19.181 ip=172.31.30.133
    node3 	 ansible_host=54.229.231.229 ip=172.31.19.206

    [kube-master]
    node1
    node2

    [kube-node]
    node1
    node2
    node3

    [etcd]
    node1
    node2
    node3

    [k8s-cluster:children]
    kube-node
    kube-master

    [calico-rr]


To start installation run following

    ansible-playbook -u ubuntu --become -i inventory.cfg cluster.yml




ansible node1 -u ubuntu --become -i inventory.cfg -m fetch -a "src=/etc/kubernetes/ssl/admin-node1.pem dest=secrets"
ansible node1 -u ubuntu --become -i inventory.cfg -m fetch -a "src=/etc/kubernetes/ssl/admin-node1-key.pem dest=secrets"
ansible node1 -u ubuntu --become -i inventory.cfg -m fetch -a "src=/etc/kubernetes/ssl/ca.pem dest=secrets"




kubectl config set preferences.colors true
kubectl config set-cluster aws-cluster --server=https://54.154.76.155 --certificate-authority=secrets/node1/etc/kubernetes/ssl/ca.pem --embed-certs=true
kubectl config set-credentials aws-admin --certificate-authority=secrets/node1/etc/kubernetes/ssl/ca.pem --client-key=secrets/node1/etc/kubernetes/ssl/admin-node1-key.pem --client-certificate=secrets/node1/etc/kubernetes/ssl/admin-node1.pem --embed-certs=true
kubectl config set-context aws-context --cluster=aws-cluster --user=aws-admin --namespace=foo



kubectl config use-context aws-context


kubectl config view
kubectl config get-contexts

kubectl config current-context
