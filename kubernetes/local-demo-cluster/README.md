# Create local VM cluster for testing Kubernetes

This directory contains Terraform and Ansible scripts to launch
cluster of VMs and install Kubernetes on the machines.

Contents of this project:

* [main.tf](main.tf) - Terraform entrypoint script that creates a cluster and a network.
* [cluster/main.tf](cluster/main.tf) - Terraform module that initializes VM, disk and cloudinit.
* [site.yml](site.yml) - Ansible script that provisions the cluster.
* [group_vars/all](group_vars/all) - Global variables for Ansible.
* [roles/docker/tasks/main.yml](roles/docker/tasks/main.yml) - Ansible role that installs Docker packages.
* [roles/kubernetes/tasks/main.yml](roles/kubernetes/tasks/main.yml) - Ansible role that installs Kubernetes packages.
* [roles/kubeadm-cluster-master/tasks/main.yml](roles/kubeadm-cluster-master/tasks/main.yml) - Ansible role that initializes Kubernetes master.
* [roles/kubeadm-cluster-node/tasks/main.yml](roles/kubeadm-cluster-node/tasks/main.yml) - Ansible role that initializes Kubernetes node.
* [ansible-inventory-from-terraform-output.py](ansible-inventory-from-terraform-output.py) - Python script that uses Terraform state to generate dynamic inventory for Ansible.
* [ssh-config-from-terraform-output.py](ssh-config-from-terraform-output.py) - Python script that uses Terraform state to generate ssh-config file.


## Prerequisites

Install [Terraform](https://www.terraform.io/downloads.html) and
[Ansible](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).

Install Terraform libvirt provider. It is available at
https://github.com/dmacvicar/terraform-provider-libvirt and it is
installed by running following (requires working go installation):

    go get github.com/dmacvicar/terraform-provider-libvirt
    mkdir -p $HOME/.terraform.d/plugins
    mv $GOPATH/bin/terraform-provider-libvirt $HOME/.terraform.d/plugins


Download ubuntu cloud image in qcow2 format and resize it so that the
disk size will be enought to install Kubernetes into it

    wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
    qemu-img resize xenial-server-cloudimg-amd64-disk1.img +5G


Initialize terraform work directory

    terraform init


Create `terraform.tfvars` with your public SSH key. This will be
included in cloudinit ISO image which libvirt provider creates
automatically, in order to inject configuration to the cloud-init
running in VMs.  The file content should look something like following

    ssh_public_key = "ssh-rsa AAAAB3Nza....WPRQ== My SSH public key"


## Manage cluster

    # create VMs
    terraform apply -auto-approve

    # install Docker and Kubernetes
    ansible-playbook site.yml

    # use kubernetes
    kubectl --kubeconfig=admin.conf get nodes

    # generate ssh-config file and connect to VM
    ./ssh-config-from-terraform-output.py > ssh-config
    ssh -F ssh-config kubernetes-1

    # destroy cluster
    terraform destroy -force
