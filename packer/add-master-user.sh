#!/bin/bash

sudo adduser --disabled-password --gecos '' master
sudo usermod -aG sudo master
echo 'master ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d/master
