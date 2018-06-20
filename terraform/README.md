## migraiton of current static ip

1. First deployment should have `static_ip = 0` in terraform/aws.tf
3. Manual one time process start here:
2. Find static ip address for region.
3. Change static_ip = 1
4. Run terraform plan you should see something similar to

````
Terraform will perform the following actions:

  + module.fleet-eu-west-2.aws_eip.ip
      id:                   <computed>
      allocation_id:        <computed>
      association_id:       <computed>
      domain:               <computed>
      instance:             <computed>
      network_interface:    <computed>
      private_ip:           <computed>
      public_ip:            <computed>
      vpc:                  <computed>

  + module.fleet-eu-west-2.aws_eip_association.ip_associate
      id:                   <computed>
      allocation_id:        "${aws_eip.ip.id}"
      instance_id:          "i-04af38a4cec3b7b0c"
      network_interface_id: <computed>
      private_ip_address:   <computed>
      public_ip:            <computed>
````
5. Now you need to import to terraform IP addres that was locked for epoch deployment
6. Make sure that you have correct region for correct fleet setup
7. ```↪ AWS_DEFAULT_PROFILE=aeternity AWS_DEFAULT_REGION=eu-west-1 terraform import module.fleet.aws_eip.ip 34.254.101.163
module.fleet.aws_eip.ip: Importing from ID "34.254.101.163"...
module.fleet.aws_eip.ip: Import complete!
  Imported aws_eip (ID: 34.254.101.163)
module.fleet.aws_eip.ip: Refreshing state... (ID: 34.254.101.163)

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.```
8. you need to run this ^ for each region.
9. After importing run terraform plan:

```
  + module.fleet-eu-west-2.aws_eip_association.ip_associate
      id:                   <computed>
      allocation_id:        "eipalloc-df0704f1"
      instance_id:          "i-04af38a4cec3b7b0c"
      network_interface_id: <computed>
      private_ip_address:   <computed>
      public_ip:            <computed>

  + module.fleet.aws_eip_association.ip_associate
      id:                   <computed>
      allocation_id:        "eipalloc-38155a05"
      instance_id:          "i-00d6250e4af76b212"
      network_interface_id: <computed>
      private_ip_address:   <computed>
      public_ip:            <computed>```

10. now terraform apply shuld change allocation to new created static node.
11. happy ever after!
