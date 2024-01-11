# Infrastructure management automation for æternity nodes

Infrastructure is orchestrated with [Terraform](https://www.terraform.io) in the following repositories:
- [Mainnet seed nodes](https://github.com/aeternity/terraform-aws-mainnet)
- [Mainnet API gateway](https://github.com/aeternity/terraform-aws-mainnet-api)
- [Testnet seed and miner nodes](https://github.com/aeternity/terraform-aws-testnet)
- [Devnet environments (integration, next, dev1, dev2, etc...)](https://github.com/aeternity/terraform-aws-devnet)
- [Miscellaneous services (release repository, backups, etc...)](https://github.com/aeternity/terraform-aws-misc)

This repository contains Ansible playbooks and scripts to bootstrap, manage, maintenance and deploy nodes.
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
ssh aeternity@192.168.1.1
```

## Credentials

All secrets are managed with [Hashicorp Vault](https://www.vaultproject.io),
so that only authentication to Vault must be configured explicitly, it needs an address and authentication secret(s):

- Vault address (can be found in the private communication channels)
    * The Vault server address can be set by `AE_VAULT_ADDR` environment variable.
- Vault secret can be provided in either of the following methods:
    - [GitHub Auth](https://www.vaultproject.io/docs/auth/github.html) by using [GitHub personal token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/#creating-a-token)
    set as `AE_VAULT_GITHUB_TOKEN` environment variable. Any valid GitHub access token with the read:org scope can be used for authentication.
    - [AppRole Auth](https://www.vaultproject.io/docs/auth/approle.html) set as `VAULT_ROLE_ID` and `VAULT_SECRET_ID` environment variables.
    - [Token Auth](https://www.vaultproject.io/docs/auth/token.html) by setting `VAULT_AUTH_TOKEN` environment variable (translates to `VAULT_TOKEN` by docker entry point). `VAULT_AUTH_TOKEN` is highest priority compared to other credentials.

Access to secrets is automatically set based on Vault policies of the authenticated account.

### Token refresh

Vault tokens expire after a certain amount of time. To continue working one MUST refresh the token.

```
make -B secrets
```

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
ssh aeternity@192.168.1.1
```

#### Users

`ssh` and `cert` targets are shorthands that actually run `ssh-aeternity` and `cert-aeternity`.
Note the `ssh-%` and `cert-%` target suffix, it could be any supported node username, e.g. `ssh-master`.
For example to ssh with `master` user (given the Vault token have the sufficient permissions):
```bash
make ssh-master HOST=192.168.1.1
```

## Ansible playbooks

You can run any playbook from `ansible/` using `make ansible/<playbook>.yml`.

Most of the playbooks can be run with aliases (used in the following examples)

The playbooks can be controlled by certain environment variables.

Most playbooks require `DEPLOY_ENV` which is the deployment environment of the node instance.

Here is a list of other optional vars that can be passed to all playbooks:

- `CONFIG_ENV` - [Vault configuration env](#vault-node-ansible-configuration), in cases when config env includes region or does not match `DEPLOY_ENV` (default: `$DEPLOY_ENV`)
- `DEPLOY_CONFIG` - Specify a local file to use instead of an autogenerated config from vault. *NOTE: The file should not be located in vault output path (`/tmp/config/`) else it will be regenerated.*
- `LIMIT` - Ansible's `--limit` option (default: `tag_env_$DEPLOY_ENV:&tag_role_aenode`)
- `HOST` - Pass IP (or a comma separated list) to use specific host
   - This will ignore `LIMIT` (uses ansible's `-i` instead of `--limit`). 
   - Make sure you run `make list-inventory` first.
- `PYTHON` - Full path of the python interpreter (default: `/usr/bin/python3`)
- `ANSIBLE_EXTRA_PARAMS` - Additional params to append to the `ansible-playbook` command
    (e.g. `ANSIBLE_EXTRA_PARAMS=--tags=task_tag -e var=val`)

Certain playbooks require additional vars, see below.

### SSH setup

To run any of the Ansible playbooks a SSH certificate (and keys) must be setup in advance.
Depending on the playbook it requires either `aeternity` or `master` SSH remote user access.

Both can be setup by running:
```bash
make cert-aeternity
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

### Setup

To setup environment of nodes, `make setup` can be used,
for example to setup `integration` environment nodes run:
```bash
make setup DEPLOY_ENV=integration
```

Nodes are usually already setup during the bootstrap process of environment creation and maintenance.

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
- DEPLOY_KIND - deploy to different kind of nodes, current is seed / peer / api (not limit by default)
- DEPLOY_REGION - deploy to different AWS Region i.e.: eu_west_2 (notice _ instead of -)
- DEPLOY_DB_VERSION - chain db directory suffix that can be bumped to purge the old db (1 by default)
- ROLLING_UPDATE - Define batch size for rolling updates: https://docs.ansible.com/ansible/latest/user_guide/playbooks_delegation.html#rolling-update-batch-size default 100%

#### Custom node config

Example for deploying by specifying config with region:
```bash
make deploy DEPLOY_ENV=uat_mon CONFIG_ENV=uat_mon@ap-southeast-1
```

Example for deploying by specifying custom node config file:
```bash
make deploy DEPLOY_ENV=dev1 DEPLOY_CONFIG=/tmp/dev1.yml
```

#### Deploy to mainnet

Full example for deploying 1.4.0 release to all mainnet nodes.

```bash
DEPLOY_VERSION=1.4.0
export DEPLOY_ENV=main
export DEPLOY_DOWNTIME=1800 #30 minutes
export DEPLOY_DB_VERSION=1 # Get the version with 'curl https://raw.githubusercontent.com/aeternity/aeternity/v${DEPLOY_VERSION}/deployment/DB_VERSION'
export PACKAGE=https://releases.aeternity.io/aeternity-${DEPLOY_VERSION}-ubuntu-x86_64.tar.gz
export ROLLING_UPDATE=100%

#ROLLING_UPDATE optional default=100%
# - examples:"50%" run on 50% of nodes in run
# - "1" ron on one node at a time
# - '[1, 2]' run 1, node then on 2 nodes etc...
# - "['10%', '50%']" run on 10% nodes then on 50% etc...
# Define batch size for rolling updates: https://docs.ansible.com/ansible/latest/user_guide/playbooks_delegation.html#rolling-update-batch-size

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

### Vault node ansible configuration

Node configurations are stored in YAML format by the Vault's KV store named 'secret'
under path `secret/aenode/config/<ENV_TAG>` as field `node_config`

`<ENV_TAG>` should be considered to be a node's "configuration" environment. 
For instance 'terraform' setups certain nodes to look for `<env@region>`, e.g. `main_mon@us-west-1`. 

Each AWS instance `<ENV_TAG>` is generated from the EC2 `env` tag or is fully specified by `node_config` tag.
It should point to the location of the vault's `node_config` field (path only).
If `node_config` is missing, empty or is set to the string `none` it will use the instance's `env` as fallback. 

When there is no env config stored in the KV database (and instance have no `node_config` tag), the bootstrapper will try to use a file in `/ansible/vars/<env>.yml`.

For quick debugging of KV config repository there are few tools provided by make.

#### List of all stored configurations:

To get a list of all Vault stored configuration <ENV_TAG>'s (environments) use:

```bash
make vault-configs-list
```

#### Dumping configurations

Configurations will be downloaded as a YAML file with filename format `<CONFIG_OUTPUT_DIR>/<ENV_TAG>.yml` 

By default `CONFIG_OUTPUT_DIR` is `/tmp/config`. You can provide it as make env variable.

You can save all configurations as separate `.yml` files in `/tmp/config`:

```bash
make vault-configs-dump
```

To dump a single configuration use `make vault-config-<ENV_TAG>`. Example for `dev1`:

```bash
make vault-config-dev1
```

Tip: To get and dump the contents in the console you can use:

```bash
cat `make -s vault-config-test`
```

#### Additional options

ENV vars can control the defaults:
- `CONFIG_OUTPUT_DIR` - To override the output path where configs are dumped (default: `/tmp/config`)
- `VAULT_CONFIG_ROOT` - Vault root path where config envs are stored (default: `secret/aenode/config`)
- `VAULT_CONFIG_FIELD` - Name of the field where the configuration YAML is stored (default: `node_config`)

Example:

```bash
make vault-configs-dump \
    CONFIG_OUTPUT_DIR=/some/dir \
    VAULT_CONFIG_ROOT=secret/some/config \
    VAULT_CONFIG_FIELD=special_config
```

### Mnesia snapshots

To snapshot a Mnesia database run:
```bash
make mnesia_snapshot DEPLOY_ENV=integration
```

To snapshot a specific node instance with IP 1.2.3.4:

```bash
make mnesia_snapshot DEPLOY_ENV=integration HOST=1.2.3.4 SNAPSHOT_SUFFIX=1234
```

Additional parameters:
- SNAPSHOT_SUFFIX - snapshot filename suffix, by default is date and time of the run, suffix can be used to set unique filename

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

### Testing Ansible playbooks

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
docker run -d --net aeternity --name aenode1804 aeternity/ubuntu-sshd:18.04
docker run -d --net aeternity --name aenode2204 aeternity/ubuntu-sshd:22.04
```

The above command will run an Ubuntu 18.04 and Ubuntu 22.04 with sshd daemon running
and reachable by other hosts in the same docker network at addresses `aenode1804.aeternity` and `aenode2204.aeternity`.

Once the test node is running, start an infrastructure container in the same docker network:

```bash
docker run -it --env-file env.list -v ${PWD}:/src -w /src --net aeternity aeternity/infrastructure
```

Running an Ansible playbook against the `aenode1804` and `aenode2204` containers requires setting [additional Ansible parameters](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#list-of-behavioral-inventory-parameters):

- inventory host - i.e. `aenode1804.aeternity`
- ssh user - `root`
- ssh password - `root`
- python interpreter - `/usr/bin/python3`

For example to run the `setup.yml` playbook:

```bash
cd ansible && ansible-playbook -i aenode1804.aeternity, \
  -e ansible_user=root \
  -e ansible_ssh_pass=root \
  -e ansible_python_interpreter=/usr/bin/python3 \
  setup.yml
```

Running/testing playbooks on localhost with docker-compose helpers.
This will run infrastructure container link it to debian container.

```bash
docker-compose up -d
#attach to local infrastructure container
docker attach infrastructure-local
./local_playbook_run.sh deploy.yml # + add required parameters
```

Certain playbooks require a `node_config` var to be provided. The most convenient way is to import a `.yml` file in the ansible env:

```bash
./local_playbook_run.sh deploy.yml \
    -e "@/tmp/config/test.yml" # + add required parameters
```

*Note: To create a .yml for the 'test' deployment env, you can use `make vault-config-test`.
See [Dumping configurations](#dumping-configurations) section for more.*

Use <kbd>CTRL+p</kbd>, <kbd>q</kbd> sequence to detach from the container.

### Integration tests

As this repository Anisble playbooks and scripts are used to bootstrap the infrastructure, integration tests are mandatory.
By default it tests the integration of `master` branch of this repository with the latest stable version of deploy Terraform module.
In the continuous integration service (CircleCI), the integration tests will be run against the branch under test.

It can be run by:

```
cd test/terraform
terraform init && terraform apply
```

After the fleet is created the expected functionality should be validated by using the AWS console or CLI.
For fast health check the Ansible playbook can be run, note that the above Terraform configuration creates an environment with name `test`:

```bash
cd ansible && ansible-playbook health-check.yml --limit=tag_env_test
```

Don't forget to cleanup the test environment after the tests are completed:

```bash
cd test/terraform && terraform destroy
```

All of the above can be run with single `make` wrapper:

```bash
make integration-tests
```

*Note these test are run automatically each day by the CI server, and can be run by other users as well. To prevent collisions you can specify unique environment ID (do not use special symbols other than "_", otherwise tests will not pass):*

```bash
make integration-tests TF_VAR_envid=tf_test_my_test_env
```

To run the tests against your branch locally, first push your branch to the remote and then:

```bash
make integration-tests TF_VAR_envid=tf_test_my_test_env TF_VAR_bootstrap_version=my_branch
```

### CircleCI configuration

CircleCI provides a [CLI tool](https://circleci.com/docs/2.0/local-cli/) that can be used to validate configuration and run jobs locally.
However as the local jobs runner has it's limitation, to fully test a workflow it's acceptable to temporary change (as little as possible) the configuration to trigger the test. However, such changes are not accepted on `master` branch.

To debug failing jobs on CircleCI, it supports [SSH debug sessions](https://circleci.com/docs/2.0/ssh-access-jobs/), one can ssh to the build container/VM and inspect the environment.

## Python requirements

Main requirements are kept in the requirements.txt file while freezed full list is kept in requirements-lock.txt
It can be updated by changing requirements.txt and generating the lock file.

```bash
pip3 install -r requirements.txt
pip3 freeze > requirements-lock.txt
```
