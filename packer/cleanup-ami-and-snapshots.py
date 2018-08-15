#!/usr/bin/env python
import boto3
region="us-west-2"
ec2_client = boto3.client('ec2',region_name=region)

epoch_image_name = "epoch-ubuntu-16.04"

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

print(get_amis_to_remove(ec2_client, epoch_image_name))
