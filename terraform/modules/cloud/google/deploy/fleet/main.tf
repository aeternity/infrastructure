resource "google_compute_address" "ip_address" {
  name    = "${var.env}-static-ip"
  project = "epoch-p2p"
  region  = "${var.region}"
}

resource "google_compute_instance" "static_node" {
  count   = "${var.static_nodes}"
  project = "epoch-p2p"
  name    = "ae-${var.env}-static-node1"
  zone    = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "${var.image_name}"
    }
  }

  machine_type = "${var.instance_type}"

  network_interface {
    network = "${var.network_name}"

    access_config {
      nat_ip = "${google_compute_address.ip_address.address}"
    }
  }

  metadata_startup_script = "${module.user_data.user_data}"

  tags = ["${var.env}"]

  labels {
    name  = "ae-${var.env}-static-node"
    env   = "${var.env}"
    role  = "epoch"
    color = "${var.color}"
  }
}

module "user_data" {
  source = "../../../../user_data/"
  region            = "${var.zone}"
  env               = "${var.env}"
  bootstrap_version = "${var.bootstrap_version}"
  epoch_package     = "${var.epoch["package"]}"
  vault_addr        = "${var.vault_addr}"
  vault_role        = "${var.vault_role}"
}

resource "google_compute_instance" "nodes" {
  count   = "${var.nodes}"
  project = "epoch-p2p"
  name    = "ae-${var.env}-node-${count.index}"
  zone    = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "${var.image_name}"
    }
  }

  machine_type = "${var.instance_type}"

  network_interface {
    network = "${var.network_name}"

    access_config {}
  }

  metadata_startup_script = "${module.user_data.user_data}"

  tags = ["${var.env}"]

  labels {
    name  = "ae-${var.env}-node-${count.index}"
    env   = "${var.env}"
    role  = "epoch"
    color = "${var.color}"
  }
}

resource "google_compute_firewall" "firewal" {
  name    = "${var.env}-firewall"
  network = "${var.network_name}"
  project = "${var.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["3013-3015"]
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.env}"]
}
