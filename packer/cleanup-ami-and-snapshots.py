#!/usr/bin/env python
import boto3

client = boto3.client('ec2',region_name=region)

print(client.describe_images())
print(client.describe_snapshots())
