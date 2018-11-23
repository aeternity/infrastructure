module "google_vpc" {
  source  = "vpc"
  env     = "${var.env}"
  project = "${var.project}"
}

module "google_fleet" {
  source            = "fleet"
  static_nodes      = "${var.static_nodes}"
  image_name        = "${var.image_name}"
  instance_type     = "${var.instance_type}"
  env               = "${var.env}"
  network_name      = "${module.google_vpc.name}"
  zone              = "${var.zone}"
  region            = "${var.region}"
  vault_addr        = "${var.vault_addr}"
  vault_role        = "${var.vault_role}"
  bootstrap_version = "${var.bootstrap_version}"
  epoch             = "${var.epoch}"
  user_data_file    = "${var.user_data_file}"
  nodes             = "${var.nodes}"
  color             = "${var.color}"
  project           = "${var.project}"
}
