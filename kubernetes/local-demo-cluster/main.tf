
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "kubernetes" {
  name      = "kubernetes"
  addresses = ["10.200.0.0/24"]
  bridge    = "kubernetes"
  autostart = "true"
}

# start cluster of VMs
module "kubernetes" {
  source = "cluster"
  num_nodes = 3
  name = "kubernetes"
  network_name = "kubernetes"
  ssh_public_key = "${var.ssh_public_key}"
}

output "hostnames" {
  value = "${module.kubernetes.hostnames}"
}

output "addresses" {
  value = "${module.kubernetes.addresses}"
}
