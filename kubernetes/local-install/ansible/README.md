
# Install docker and kubernetes packages with Ansible

This directory contains Ansible roles to configure package
repositories, signing keys and to install docker-ce and kubernetes
packages.  These can be used as an alternative to manual
configuration.

To run the playbook, first define your master and worker hostnames to
`inventory.ini`.  Then execute

    ansible-playbook deploy.yml


## Connect to worker nodes via jump server

In some cases the Kubernetes cluster may be installed in a way that
nodes are not directly reachable by SSH.  For example workers need to
be accessed by connecting through master node as a jump host.

Create `ssh-config` with following contents:

    Host my-worker-*
      ProxyCommand ssh -W %h:%p ubuntu@my-master-hostname


Here `my-worker-*` is a hostname pattern that matches with worker
hostnames listed in `inventory.ini`.  The workers must be reachable
with those names from the jump host.  The jump host is specified in the
ProxyCommand as target when connecting to the workers.

Run ansible-playbook with following paramteres to utilize the jump
host configuration:

    ANSIBLE_SSH_ARGS="-A -F ssh-config" ansible-playbook deploy.yml
