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

ENV VAULT_VERSION=0.11.2
RUN curl -sSO https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
    && unzip vault_${VAULT_VERSION}_linux_amd64.zip -d /bin \
    && rm -f vault_${VAULT_VERSION}_linux_amd64.zip

ENV DOCKER_CLIENT_VERSION=20.10.11
RUN curl -L -o /tmp/docker-${DOCKER_CLIENT_VERSION}.tgz \
    https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLIENT_VERSION}.tgz \
    && tar -xz -C /tmp -f /tmp/docker-${DOCKER_CLIENT_VERSION}.tgz \
    && mv /tmp/docker/docker /bin

COPY --from=docker/buildx-bin:0.7.1 /buildx /usr/libexec/docker/cli-plugins/docker-buildx

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

ENV TFENV_VERSION=2.2.2
RUN curl -L -o /tmp/tfenv-${TFENV_VERSION}.tar.gz \
    https://github.com/tfutils/tfenv/archive/refs/tags/v${TFENV_VERSION}.tar.gz \
    && tar -xz -C /usr/local -f /tmp/tfenv-${TFENV_VERSION}.tar.gz

RUN ln -s /usr/local/tfenv-${TFENV_VERSION}/bin/tfenv /usr/local/bin/
RUN ln -s /usr/local/tfenv-${TFENV_VERSION}/bin/terraform /usr/local/bin/

#Install last release for "old" versions of TF for purpose of migrations
#this will be removed after migration process finished

RUN tfenv install 0.12.21
RUN tfenv install 0.13.7
RUN tfenv install 0.14.11
RUN tfenv install 0.15.5
RUN tfenv install 1.1.4

ENV TERRAFORM_DEFAULT_VERSION 0.12.30
RUN tfenv install ${TERRAFORM_DEFAULT_VERSION}
RUN tfenv use ${TERRAFORM_DEFAULT_VERSION}

ADD . /infrastructure
WORKDIR /infrastructure

ENV SHELL /bin/bash
CMD ["/bin/bash", "--login"]
