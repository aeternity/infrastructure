data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.bash")}"

  vars = {
    region            = "${var.region}"
    env               = "${var.env}"
    bootstrap_version = "${var.bootstrap_version}"
    epoch_package     = "${var.epoch_package}"
    vault_addr        = "${var.vault_addr}"
    vault_role        = "${var.vault_role}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
