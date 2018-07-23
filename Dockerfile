FROM alpine:3.8

# Symlink python to python3 to workaround ansible_python_interpreter issue that need to be set per host.
# Some of the playbooks run on multiple hosts: local + remote.
# If it's set in the inventory it will not work when a specific inventory is used.
RUN apk add --no-cache bash curl unzip make python3 py-cryptography openssh-client \
    && ln -s /usr/bin/python3 /usr/bin/python

ENV PACKER_VERSION=1.2.4
RUN curl -sSO https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /bin \
    && rm -f packer_${PACKER_VERSION}_linux_amd64.zip

ENV TERRAFORM_VERSION 0.11.7
RUN curl -sSO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin \
    && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

ADD requirements.txt /infrastructure/
RUN apk add --no-cache --virtual build-deps \
        gcc python3-dev musl-dev openssl-dev libffi-dev linux-headers \
    && pip3 install --no-cache-dir -r /infrastructure/requirements.txt \
    && apk del build-deps

ADD ansible/requirements.yml /infrastructure/ansible/
RUN cd /infrastructure/ansible && ansible-galaxy install -r requirements.yml

ADD . /infrastructure
WORKDIR /infrastructure
