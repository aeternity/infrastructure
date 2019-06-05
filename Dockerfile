FROM alpine:3.8

# Symlink python to python3 to workaround ansible_python_interpreter issue that need to be set per host.
# Some of the playbooks run on multiple hosts: local + remote.
# If it's set in the inventory it will not work when a specific inventory is used.
# OpenSSL required for a packer workaround: https://github.com/hashicorp/packer/issues/2526
RUN apk add --no-cache bash curl unzip make python3 py-cryptography openssh-client openssl sshpass jq bc git\
    && ln -s /usr/bin/python3 /usr/bin/python

ENV PACKER_VERSION=1.3.2
RUN curl -sSO https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /bin \
    && rm -f packer_${PACKER_VERSION}_linux_amd64.zip

ENV TERRAFORM_VERSION 0.11.13
RUN curl -sSO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin \
    && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

ENV VAULT_VERSION=0.11.2
RUN curl -sSO https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
    && unzip vault_${VAULT_VERSION}_linux_amd64.zip -d /bin \
    && rm -f vault_${VAULT_VERSION}_linux_amd64.zip

ENV DOCKER_CLIENT_VERSION=17.09.0-ce
RUN curl -L -o /tmp/docker-${DOCKER_CLIENT_VERSION}.tgz \
    https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLIENT_VERSION}.tgz \
    && tar -xz -C /tmp -f /tmp/docker-${DOCKER_CLIENT_VERSION}.tgz \
    && mv /tmp/docker/docker /bin

ENV GOSS_VER=v0.3.6
RUN curl -L https://github.com/aelsabbahy/goss/releases/download/${GOSS_VER}/goss-linux-amd64 \
    -o /usr/bin/goss \
    && chmod +rx /usr/bin/goss

ADD requirements.txt /infrastructure/
RUN apk add --no-cache --virtual build-deps \
        gcc python3-dev musl-dev openssl-dev libffi-dev linux-headers \
    && pip3 install --upgrade pip==18.1 \
    && pip3 install --no-cache-dir -r /infrastructure/requirements.txt \
    && apk del build-deps

ADD ansible/requirements.yml /infrastructure/ansible/
RUN cd /infrastructure/ansible && ansible-galaxy install -r requirements.yml

ADD docker/ssh_config /etc/ssh/ssh_config

ADD . /infrastructure
WORKDIR /infrastructure

ENV SHELL /bin/bash
CMD ["/bin/bash", "--login"]
