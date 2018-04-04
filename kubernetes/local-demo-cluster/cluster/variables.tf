
variable "num_nodes" {
  description = "number of nodes in the cluster"
  default = 1
}

variable "ssh_public_key" {
  description = "SSH public key injected via cloud-init"
}

variable "memory" {
  default = 2048
}

variable "image" {
  default = "xenial-server-cloudimg-amd64-disk1.img"
}

variable "name" {
  description = "cluster name, used as prefix to make domain and volume resources unique"
}

variable "network_name" {
  description = "network to attach the cluster VMs"
}
