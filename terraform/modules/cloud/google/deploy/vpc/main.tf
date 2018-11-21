resource "google_compute_network" "vpc" {
  name                    = "${var.env}"
  auto_create_subnetworks = "true"
}

output "name" {
  value = "${google_compute_network.vpc.name}"
}
