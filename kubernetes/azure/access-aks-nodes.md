
# How to connect to Azure AKS Kubernetes worker node by SSH

Nodes are not assigned public IP. If you have accessible VM in the same VNET as worker nodes,
then you can use that VM as jump host and connect the worker via private IP.

Alternatively public IP can be assigned to a worker node.  This readme shows how to do that.

## Steps how to attach public IP to a worker node

find out the resource group that AKS created for the node VMs

    az group list -o table

list resources in the group and find the VM you want to access

    az resource list -g MC_kubernetes_kubernetes-cluster_ukwest -o table

show parameters of that VM, see for example: "adminUsername": "azureuser"

    az vm show -g MC_kubernetes_kubernetes-cluster_ukwest -n aks-agentpool1-18549766-0

create the public IP

    az network public-ip create -g MC_kubernetes_kubernetes-cluster_ukwest -n test-ip

find out correct NIC where to add the public IP

    az network nic list -g MC_kubernetes_kubernetes-cluster_ukwest -o table

find out the name of the ipconfig within that NIC

    az network nic ip-config list --nic-name aks-agentpool1-18549766-nic-0 -g MC_kubernetes_kubernetes-cluster_ukwest

modify the ipconfig by adding the public IP address

    az network nic ip-config update -g MC_kubernetes_kubernetes-cluster_ukwest --nic-name aks-agentpool1-18549766-nic-0 --name ipconfig1 --public-ip-address test-ip

find out what the allocated public IP address is

    az network public-ip show -g MC_kubernetes_kubernetes-cluster_ukwest -n test-ip

then finally connect with SSH

    ssh azureuser@<public ip address>
