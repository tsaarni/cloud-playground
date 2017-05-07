

variable "region" {}
variable "region_zone" {}
variable "project_name" {}
variable "credentials_file_path" {}


provider "google" {
  project     = "${var.project_name}"
  region      = "${var.region}"
}


resource "google_compute_instance" "dev" {
  name         = "dev"
  machine_type = "f1-micro"
  zone         = "${var.region_zone}"

  # https://cloud.google.com/compute/docs/images
  disk {
    image = "family/ubuntu-1704"
  }

  network_interface {
    network = "default"

    access_config {
      # Ephemeral
    }
  }

  metadata {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

}

output "public_ips" {
  value = ["${google_compute_instance.dev.network_interface.0.access_config.0.assigned_nat_ip}"]
}
