#!/bin/bash

while sudo fuser -s /var/lib/dpkg/lock; do
    echo "Waiting for apt to release the dpkg lock ..."
    sleep 5
done

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade -o Dpkg::Options::="--force-confnew"
