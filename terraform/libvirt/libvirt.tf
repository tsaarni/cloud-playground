
variable "ssh_public_key" {}

provider "libvirt" {
  uri = "qemu:///system"
}

# create network
resource "libvirt_network" "network" {
   name = "network"
   addresses = ["10.0.1.0/24"]
}

# create cloudinit .iso
resource "libvirt_cloudinit" "cloudinit" {
  name               = "cloudinit.iso"
  ssh_authorized_key = "${var.ssh_public_key}"
}

# create disks for VMs
resource "libvirt_volume" "volume" {
  name   = "volume-ubuntu-${count.index}"
  source = "ubuntu-16.04-server-cloudimg-amd64-disk1.img"
  count  = 4
}

# create VMs
resource "libvirt_domain" "domain" {
  name      = "domain-ubuntu-${count.index}"
  memory    = "1024"
  cloudinit = "${libvirt_cloudinit.cloudinit.id}"
  count     = 4
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


output "ip" {
  value = ["${libvirt_domain.domain.*.network_interface.0.addresses.0}"]
}
