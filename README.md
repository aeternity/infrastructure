# Infrastructure management automation for æternity nodes

Infrastructure is automatically created and managed by Ansible playbooks run by CircleCI.
Only changes to master branch are deployed.
Infrastructure is orchestrated with [OpenStack Heat](https://docs.openstack.org/heat/latest/) and [AWS CloudFormation](https://aws.amazon.com/cloudformation/).
Ansible playbooks are run against [dynamic host inventories](http://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html).

Below documentation is meant for manual testing and additional details. It's already integrated in CircleCI workflow.

## Requirements

The only requirement is Docker. All the libraries and packages are built in the docker image.
If for some reason one needs to setup the requirements on the host system see the Dockerfile.

## Credentials setup

### OpenStack
You should make sure [OpenStack credentials are set](https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#environment-variables)
either by environment variables or clouds.yml file.

```bash
source ~/my/secrets/openstack.rc
```

### Amazon Web Services

Yous should make sure [AWS CommandLine interface credentials are set](http://docs.ansible.com/ansible/latest/intro_dynamic_inventory.html#example-aws-ec2-external-inventory-script)
either by environment variables or `~/.aws/credentials` file.

If you have configured multiple AWS credentials you can pass AWS_PROFILE variable before the commands:

```bash
AWS_PROFILE=aeternity ansible-inventory --list
```

### Ansible Secrets

Secrets are managed with [Ansible Vault](docs.ansible.com/ansible/2.4/vault.html).
There is a tiny bridge vault file `vault-env` that bridges the `INFRASTRUCTURE_ANSIBLE_VAULT_PASSWORD` environment variable as Ansible vault password.

```
export INFRASTRUCTURE_ANSIBLE_VAULT_PASSWORD="top secret"
```

## Docker image

A Docker image `aeternity/infrastructure` is build and published to DockerHub. To use the image one should configure all the required credentials as documented above and run the container:

```bash
docker run -it --env-file env.list -v ~/.ssh/:/root/.ssh/ aeternity/infrastructure
```

Then in the container shell setup your private SSH key:

```bash
eval $(ssh-agent)
ssh-add -k ~/.ssh/id_rsa
```

## Ansible playbooks

### Ansible dynamic inventory

Check that your OpenStack and AWS credentials are setup and dynamic inventory is working as excepted:
```bash
cd ansible && ansible-inventory --list
```

### Infrastructure setup

An environment infrastructure can be setup with `make setup`,
for example to setup `integration` environment infrastructure run:
```bash
make setup DEPLOY_ENV=integration
```

To create new environment edit the `ansible/environments.yml` playbook.

### Manage nodes

Start, stop, restart or ping nodes by running:
```bash
make manage-node DEPLOY_ENV=integration CMD=start
make manage-node DEPLOY_ENV=integration CMD=stop
make manage-node DEPLOY_ENV=integration CMD=restart
make manage-node DEPLOY_ENV=integration CMD=ping
```

### Reset network of nodes

To reset a network of nodes run:
```bash
make reset-net DEPLOY_ENV=integration
```

The playbook does:

- delete blockchain data
- delete logs
- delete chain keys

## Base images

Pre-built base images are used to speedup initial provisioning of node instances. It does not have a functional impact on node setups as the same Ansible playbooks are used.

Base images can be build manually on local environments by running:
```bash
packer build packer/epoch.json
```

In case local environment is not (or cannot be) setup with [cloud credentials](#credentials-setup), a CI trigger branch `packer` can be used by pushing to it:

```bash
git push origin master:packer
```

That will trigger CI workflow which will run the packer command for you with all required credentials already setup.
