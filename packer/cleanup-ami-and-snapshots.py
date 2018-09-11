#!/usr/bin/env python
import boto3
from botocore.exceptions import ClientError

REGIONS = [
    "us-west-2",
    "eu-central-1",
    "ap-southeast-1",
    "eu-west-2"
]

EPOCH_IMAGE_NAME = "epoch-ubuntu-16.04"

def get_account_id():
    sts = boto3.client("sts")
    return sts.get_caller_identity()["Account"]

def get_stale_amis(ec2_client, epoch_image_name):
    amis = []
    images = ec2_client.describe_images(
        Filters = [
            {
                "Name": "name",
                "Values": [
                epoch_image_name + "*"
                ]
            }
        ],
        Owners = [
            get_account_id()
        ]
    )
    used_amis = get_used_amis(ec2_client)

    for image in images["Images"]:
        if image["ImageId"] not in used_amis:
            snaps = []
            for block in image["BlockDeviceMappings"]:
                if "Ebs" in block:
                    snaps.append(block["Ebs"]["SnapshotId"])
            amis.append({"ImageId": image["ImageId"],"CreationDate": image["CreationDate"],"Snapshots": snaps})

    amis.sort(key=lambda image: image["CreationDate"], reverse = True)

    return amis[3:]

def get_used_amis(ec2_client):
    used_amis = []
    response = ec2_client.describe_instances()

    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            used_amis.append(instance["ImageId"])
    return list(set(used_amis))

def deregister(ec2_client, ids):
    for i in ids:

        ec2_client.deregister_image(
            ImageId = i["ImageId"]
        )

        for snap in i["Snapshots"]:
            ec2_client.delete_snapshot(
                SnapshotId = snap
        )

try:
    for region in REGIONS:
        ec2_client = boto3.client('ec2',region_name=region)
        deregister(ec2_client, get_stale_amis(ec2_client, EPOCH_IMAGE_NAME))

except:
    print("Unexpected error:", sys.exc_info()[0])
    exit(1)
