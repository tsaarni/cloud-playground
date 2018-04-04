
variable "ssh_public_key" {}
variable "num_servers" {
  default = 4
}


provider "libvirt" {
  uri = "qemu:///system"
}

# create network
resource "libvirt_network" "network" {
  name = "network"
  addresses = ["10.0.1.0/24"]
  autostart = true
}

# create cloudinit .iso's for VMs
resource "libvirt_cloudinit" "cloudinit" {
  name               = "cloudinit-${count.index + 1}.iso"
  count              = "${var.num_servers}"
  local_hostname     = "ubuntu-${count.index + 1}"
  ssh_authorized_key = "${var.ssh_public_key}"
  user_data          = <<EOF
#cloud-config
runcmd:
  # cloud-init sets hostname after DHCP request has already been sent,
  # restart networking now, so we get hostname registered to dnsmasq
  - [ systemctl, restart, networking ]
EOF
}

# create disks for VMs
resource "libvirt_volume" "volume" {
  name   = "ubuntu-${count.index}"
  source = "xenial-server-cloudimg-amd64-disk1.img"
  count  =  "${var.num_servers}"
}

# create VMs
resource "libvirt_domain" "servers" {
  name      = "ubuntu-${count.index}"
  memory    = "2048"
  #autostart = true
  cloudinit = "${element(libvirt_cloudinit.cloudinit.*.id, count.index)}"
  count     = "${var.num_servers}"
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
      type        = "pty"
      target_type = "virtio"
      target_port = "1"
  }
  network_interface {
    network_name = "network"
  }

  disk {
    volume_id = "${element(libvirt_volume.volume.*.id, count.index)}"
  }

}

