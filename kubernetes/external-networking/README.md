
# Kubernetes external networking

## Overview

The scripts in this project are for learning Kubernetes external networking and traffic isolation.

Following VMs are created by Vagrantfile

- kubernetes
- oam
- traffic

Each VM is connected to VirtualBox NAT for inbound SSH connections. Additionally there are two VirtualBox internal networks:

- oam (subnet 10.10.11.0/24)
- traffic (subnet 10.10.12.0/24)

Kubernetes VM is connected to both networks.  Oam VM is connected to `oam` network.  Traffic VM is connected to `traffic` network. See [Vagrantfile](Vagrantfile).

Metallb allocates external virtual IP addresses either from `oam` and `traffic` networks for services of `type: LoadBalancer` according to annotations in the Service resources.
The virtual addresses are announced using `layer2` feature of metallb.  See [provisioning/install-metallb.sh](provisioning/install-metallb.sh).

The `oam` and `traffic` external networks can be accessed from the two external VMs in order to demonstrate accessing 
the exposed services.  Services exposed to `oam` network cannot be accessed from `traffic` network and vice versa.


## Instructions

To start the environment and to install Kubernetes and all dependencies run

    vagrant up


Connect to the VMs by running

    vagrant ssh kubernetes
    vagrant ssh oam
    vagrant ssh traffic


Follow the instructions given in the demo the scripts (`*.sh` in the root directory of this project).

