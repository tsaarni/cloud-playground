
# Using Terraform with libvirt

Libvirt provider is available at https://github.com/dmacvicar/terraform-provider-libvirt

## Install

    go get github.com/dmacvicar/terraform-provider-libvirt
    mkdir -p $HOME/.terraform.d/plugins
    mv $GOPATH/bin/terraform-provider-libvirt $HOME/.terraform.d/plugins


## Usage

Initialize Terraform working directory

    terraform init


Create `terraform.tfvars` with your public SSH key. This will be
included in `cloudinit.iso` which libvirt pfovider creates
automatically, in order to inject configuration to the cloud-init
running in VMs.  The file content should look something like following

    ssh_public_key = "ssh-rsa AAAAB3Nza....WPRQ== My SSH public key"


Download Ubuntu cloud image

    wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img


Show execution plan

    terraform plan


Apply the changes

    terraform apply


After the changes have been executed, you can list IP addresses of
running VMs by running

    virsh list --state-running --name | tee echo | xargs -n1 --verbose virsh domifaddr | grep vnet





## Problems

### State gets corrupted

If terraform state gets corrupted and is not in sync with libvirt
anymore, use following comments to remove VMs, volumes and networks to
start from scratch

    # list all VMs, destroy and undefine them
    virsh list --all
    virsh destroy <NAME>
    virsh undefine <NAME>

    # list all volumes and delete them
    virsh vol-list default
    virsh vol-delete --pool default <NAME

    # list all networks and undefine them
    virsh net-list --all
    virsh net-undefine <NAME>

    # list terraform state and remove resources
    terraform state list
    terraform rm <NAME>
