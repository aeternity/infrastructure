resource "aws_iam_role" "epoch" {
  name = "${data.aws_region.current.name}-${var.env}-epoch"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "epoch" {
  name = "${data.aws_region.current.name}-${var.env}-epoch"
  role = "${aws_iam_role.epoch.name}"
}

resource "aws_iam_role_policy" "epoch_policy" {
  name = "${data.aws_region.current.name}-${var.env}-epoch"
  role = "${aws_iam_role.epoch.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:datadog_api_key*"
    }
  ]
}
EOF
}

data "aws_caller_identity" "current" {}
