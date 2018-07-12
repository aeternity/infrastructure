FROM alpine:3.8

RUN apk add --no-cache curl unzip make python3 py-cryptography openssh-client

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
