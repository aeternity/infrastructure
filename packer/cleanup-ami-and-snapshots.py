#!/usr/bin/env python
import boto3
from botocore.exceptions import ClientError

regions=["us-west-2","eu-west-1","ap-southeast-1"]


def get_account_id():
    sts = boto3.client("sts")
    return sts.get_caller_identity()["Account"]

def get_amis_to_remove(ec2_client, epoch_image_name):
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
            amis.append({"ImageId": image["ImageId"],"CreationDate": image["CreationDate"],"Snapshoots": snaps})

    amis.sort(key=lambda image: image["CreationDate"])
    return amis[:3]


def get_used_amis(ec2_client):
    used_amis = []
    response = ec2_client.describe_instances()

    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            used_amis.append(instance["ImageId"])
    return list(set(used_amis))

def deregister(ec2_client, ids):
    for i in ids:
        try:
            ec2_client.deregister_image(
                ImageId = i["ImageId"]
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'InvalidAMIID.Unavailable':
                print("Already deleted")
            else:
                print("Unexpected error: %s" % e)
        for snap in i["Snapshoots"]:
            ec2_client.delete_snapshot(
                SnapshotId = snap
            )



for region in regions:
    ec2_client = boto3.client('ec2',region_name=region)
    epoch_image_name = "epoch-ubuntu-16.04"
    deregister(ec2_client, get_amis_to_remove(ec2_client, epoch_image_name))
