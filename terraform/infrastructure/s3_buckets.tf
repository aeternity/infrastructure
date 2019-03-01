resource "aws_s3_bucket" "aeternity-database-backups" {
  provider = "aws.eu-central-1"
  bucket   = "aeternity-database-backups"

  acl           = "private"
  force_destroy = false
  region        = "eu-central-1"
}

resource "aws_s3_bucket" "aeternity-node-releases" {
  provider      = "aws.eu-central-1"
  bucket        = "aeternity-node-releases"
  region        = "eu-central-1"
  acl           = "public-read"
  force_destroy = false
}

resource "aws_s3_bucket" "aeternity-node-builds" {
  provider = "aws.eu-central-1"
  bucket   = "aeternity-node-builds"

  acl           = "public-read"
  force_destroy = false

  lifecycle_rule {
    enabled                                = true
    abort_incomplete_multipart_upload_days = 2

    expiration {
      days = 5
    }
  }
}
