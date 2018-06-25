output "instance_type" {
  value = "m4.large"
}

output "spot_nodes" {
  value = "1"
}

output "ami_id" {
  value = {
    "ap-southeast-1" = "ami-a16367dd"
  }
}
