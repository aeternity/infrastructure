# Infrastructure management automation for æternity nodes

Infrastructure is automatically created and managed by Ansible playbooks run by CircleCI.
Only changes to master branch are deployed.
Infrastructure is orchestrated with [Terraform](https://www.terraform.io).
Ansible playbooks are run against [dynamic host inventories](http://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html).

Below documentation is meant for manual testing and additional details. It's already integrated in CircleCI workflow.

## Requirements

The only requirement is Docker. All the libraries and packages are built in the docker image.
If for some reason one needs to setup the requirements on the host system see the Dockerfile.

## Getting started

This is intended to be used as fast setup recipe, for additional details read the documentation below.

Setup Vault authentication:

```bash
export AE_VAULT_ADDR=https://the.vault.address/
export AE_VAULT_GITHUB_TOKEN=your_personal_github_token
```

Run the container:

```
docker pull aeternity/infrastructure
docker run -it -e AE_VAULT_ADDR -e AE_VAULT_GITHUB_TOKEN aeternity/infrastructure
```

Make sure there are no authentication errors after running the container.

SSH to any host:

```bash
make cert
ssh epoch@192.168.1.1
```

## Credentials

All secrets are managed with [Hashicorp Vault](https://www.vaultproject.io),
so that only authentication to Vault must be configured explicitly, it needs an address, authentication secret(s) and role:

- Vault address (can be found in the private communication channels)
    * The Vault server address can be set by `AE_VAULT_ADDR` environment variable.
- Vault secret can be provided in either of the following methods:
    - [GitHub Auth](https://www.vaultproject.io/docs/auth/github.html) by using [GitHub personal token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/#creating-a-token)
    set as `AE_VAULT_GITHUB_TOKEN` environment variable. Any valid GitHub access token with the read:org scope can be used for authentication.
    - [AppRole Auth](https://www.vaultproject.io/docs/auth/approle.html) set as `VAULT_ROLE_ID` and `VAULT_SECRET_ID` environment variables.
    - [Token Auth](https://www.vaultproject.io/docs/auth/token.html) by setting `VAULT_AUTH_TOKEN` environment variable (translates to `VAULT_TOKEN` by docker entry point). `VAULT_AUTH_TOKEN` is highest priority compared to other credentials.
- Vault credentials role by setting `VAULT_SECRETS_ROLE` (defaults to `ae-inventory`)
    - `ae-inventory` allows SSH as `epoch` user to all nodes and using Ansible dynamic inventories, together allowing a deployment. All developers are authorized.
    - `ae-fleet-manager` allows SSH as `master` user to all nodes and managing the infrastructure (AWS and GCP) - creating, dropping and changing environments (running Terraform). Only devops.

## Docker image

A Docker image `aeternity/infrastructure` is build and published to DockerHub. To use the image one should configure all the required credentials as documented above and run the container (always make sure you have the latest docker image):

```bash
docker pull aeternity/infrastructure
docker run -it -e AE_VAULT_ADDR -e AE_VAULT_GITHUB_TOKEN aeternity/infrastructure
```

For convenience all the environment variables are listed in `env.list` file that can be used instead of explicit CLI variables list,
however the command below is meant to be run in a path of this repository clone:

```bash
docker run -it --env-file env.list aeternity/infrastructure
```

### SSH

According to the Vault authentication token permissions, one can ssh to any node they have access to by running:

```bash
make ssh HOST=192.168.1.1
```

#### Certificates

SSH certificates (and keys) can be explicitly generated by running:

```bash
make cert
```

Then the regular ssh/scp commands could be run:
```bash
ssh epoch@192.168.1.1
```

#### Users

`ssh` and `cert` targets are shorthands that actually run `ssh-epoch` and `cert-epoch`.
Note the `ssh-%` and `cert-%` target suffix, it could be any supported node username, e.g. `ssh-master`.
For example to ssh with `master` user (given the Vault token have the sufficient permissions):
```bash
make ssh-master HOST=192.168.1.1
```

## Ansible playbooks

### SSH setup

To run any of the Ansible playbooks a SSH certificate (and keys) must be setup in advance.
Depending on the playbook it requires either `epoch` or `master` SSH remote user access.

Both can be setup by running:
```bash
make cert-epoch
```

and/or

```bash
make cert-master
```

Please note that only devops are authorized to request `master` user certificates.

### Ansible dynamic inventory

Check that your AWS credentials are setup and dynamic inventory is working as excepted:
```bash
cd ansible && ansible-inventory --list
```

### List inventory

Get a list of ansible inventory grouped by seed nodes and peers

```
make list-inventory
```

Inventory data is stored in local file `ansible/inventory-list.json`. To refresh it you can `make -B list-inventory`

### Infrastructure setup

An environment infrastructure can be setup with `make setup`,
for example to setup `integration` environment infrastructure run:
```bash
make setup DEPLOY_ENV=integration
```

Also the configuration is in process of migration to Terraform, thus it should be run as well:
```bash
make setup-terraform
```

To create new environment edit the `ansible/environments.yml` playbook and `terraform/main.tf`.

### Manage nodes

Start, stop, restart or ping nodes by running:
```bash
make manage-node DEPLOY_ENV=integration CMD=start
make manage-node DEPLOY_ENV=integration CMD=stop
make manage-node DEPLOY_ENV=integration CMD=restart
make manage-node DEPLOY_ENV=integration CMD=ping
```

### Deploy

To deploy aeternity package run:
```bash
export PACKAGE=https://github.com/aeternity/aeternity/releases/download/v1.4.0/aeternity-1.4.0-ubuntu-x86_64.tar.gz
make deploy DEPLOY_ENV=integration
```

Additional parameters:
- DEPLOY_DOWNTIME - schedule a downtime period (in seconds) to mute monitoring alerts (0 by default e.g. monitors are not muted)
- DEPLOY_COLOR - some environments might be colored to enable blue/green deployments (not limits by default)
- DEPLOY_DB_VERSION - chain db directory suffix that can be bumped to purge the old db (0 by default)

#### Deploy to mainnet

Full example for deploying 1.4.0 release to all mainnet nodes.

```bash
DEPLOY_VERSION=1.4.0
export DEPLOY_ENV=main
export DEPLOY_DOWNTIME=1800 #30 minutes
export DEPLOY_DB_VERSION=$(curl https://raw.githubusercontent.com/aeternity/aeternity/v${DEPLOY_VERSION}/deployment/DB_VERSION)
export PACKAGE=https://github.com/aeternity/aeternity/releases/download/v${DEPLOY_VERSION}/aeternity-${DEPLOY_VERSION}-ubuntu-x86_64.tar.gz
make cert && make deploy
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

### Mnesia backups

To backup a Mnesia database (snapshot) run:
```bash
make mnesia_backup BACKUP_ENV=integration
```

Additional parameters:
- BACKUP_SUFFIX - backup filename suffix, by default the destination file is overwritten (per host), suffix can be used to set unique filename
- BACKUP_DIR - destination directory of backup files

## Data share

The easiest way to share data between a container and the host is using [bind mounts](https://docs.docker.com/storage/bind-mounts/).
For example during development is much easier to edit the source on the host and run/test in the container,
that way you don't have to rebuild the container with each change to test it.
Bind mounting the source files to the container makes this possible:

```bash
docker run -it --env-file env.list -v ${PWD}:/src -w /src aeternity/infrastructure
```

The same method can be used to share data from the container to the host, it's two-way sharing.

An alternative method for one shot transfers could be [docker copy command](https://docs.docker.com/engine/reference/commandline/cp/).

## Testing

### Dockerfile

To test any Dockerfile or (entrypoint) changes a local container can be build and run:

```bash
docker build -t aeternity/infrastructure:local .
docker run -it --env-file env.list aeternity/infrastructure:local
```

### Ansible playbooks

#### Dev environments

The most easy way to test Ansible playbooks is to run it against dev environments.
First claim a dev environment in the chat and then run the playbook against it:

#### Local docker

Local docker containers can be used for faster feedback loops at the price of some extra docker setup.

To enable network communication between the containers, all the containers that needs to communicate has to be in the same docker network:

```bash
docker network create aeternity
```

The infrastructure docker image cannot be used because it's based on Alpine but aeternity node should run on Ubuntu.
Thus an Ubuntu based container should be run, a convenient image with sshd is `rastasheep/ubuntu-sshd`.
Note the `net` and `name` parameters:

```bash
docker pull rastasheep/ubuntu-sshd:16.04
docker run -d --net aeternity --name aenode rastasheep/ubuntu-sshd:16.04
```

The above command will run an Ubuntu 16.04 with sshd daemon running
and reachable by other hosts in the same docker network at address `aenode.aeternity`.

Once the test node is running, start an infrastructure container in the same docker network:

```bash
docker run -it --env-file env.list -v ${PWD}:/src -w /src --net aeternity aeternity/infrastructure
```

Running an Ansible playbook against the `aenode` container requires setting [additional Ansible parameters](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#list-of-behavioral-inventory-parameters):

- inventory host - `aenode.aeternity`
- ssh user - `root`
- ssh password - `root`
- python interpreter - `/usr/bin/python3`

For example to run the `setup.yml` playbook:

```bash
cd ansible && ansible-playbook -i aenode.aeternity, \
  -e ansible_user=root \
  -e ansible_ssh_pass=root \
  -e ansible_python_interpreter=/usr/bin/python3 \
  setup.yml
```

### Terraform configuration

To test Terraform configuration changes, a new test configuration can be created then run.
Another option would be changing the `test/terraform/test.tf` configuration and applying it:

```
cd test/terraform
terraform init && terraform apply
```

After the fleet is create the expected functionality should be validated by using the AWS console or CLI.
For fast health check the ansible playbook can be used, note that the above Terraform configuration creates an environment with name `tf_test`:

```bash
cd ansible && ansible-playbook health-check.yml --limit=tag_env_tf_test
```

Don't forget to cleanup the test environment after the tests are completed:

```bash
cd test/terraform && terraform destroy
```

All of the above can be run with single `make` wrapper:

```bash
make integration-tests
```

*Note that this environment is also used and run automatically each day by the CI server, it also can be run by other users as well. It's not designed to be multi-user yet, so a bit of coordination should be made to prevent collisions*

### CircleCI configuration

CircleCI provides a [CLI tool](https://circleci.com/docs/2.0/local-cli/) that can be used to validate configuration and run jobs locally.
However as the local jobs runner has it's limitation, to fully test a workflow it's acceptable to temporary change (as little as possible) the configuration to trigger the test. However, such changes are not accepted on `master` branch.

To debug failing jobs on CircleCI, it supports [SSH debug sessions](https://circleci.com/docs/2.0/ssh-access-jobs/), one can ssh to the build container/VM and inspect the environment.
