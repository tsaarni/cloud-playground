


resource "libvirt_cloudinit" "cloudinit" {
  name               = "${var.name}-${count.index + 1}-cloudinit.iso"
  count              = "${var.num_nodes}"
  local_hostname     = "${var.name}-${count.index + 1}"
  ssh_authorized_key = "${var.ssh_public_key}"
  user_data          = <<EOF
#cloud-config
runcmd:
  # cloud-init sets hostname after DHCP request has already been sent,
  # restart networking now, so we get hostname registered to dnsmasq
  - systemctl restart networking
  - ln -s python3 /usr/bin/python
packages:
  - python3
EOF
}

resource "libvirt_volume" "volume" {
  name   = "${var.name}-${count.index + 1}-volume"
  count  = "${var.num_nodes}"
  source = "xenial-server-cloudimg-amd64-disk1.img"
}

resource "libvirt_domain" "domain" {
  name      = "${var.name}-${count.index + 1}"
  count     = "${var.num_nodes}"
  memory    = "${var.memory}"
  vcpu      = 2     # master node needs at least 2 vcpus
  #autostart = true
  cloudinit = "${element(libvirt_cloudinit.cloudinit.*.id, count.index)}"
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
    network_name = "${var.network_name}"
  }

  disk {
    volume_id = "${element(libvirt_volume.volume.*.id, count.index)}"
  }

}


output "hostnames" {
  value = ["${libvirt_domain.domain.*.name}"]
}

output "addresses" {
  value = ["${libvirt_domain.domain.*.network_interface.0.addresses}"]
}
