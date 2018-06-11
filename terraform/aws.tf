provider "aws" {
  version                 = "1.22"
  region                  = "us-west-2"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}


resource "aws_instance" "web" {
  count = 2
  ami           = "ami-5ea58927"
  instance_type = "t2.micro"

  tags {
    Name = "HelloWorld-n${count.index}"
  }
}
