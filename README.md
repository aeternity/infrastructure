# Infrastructure management automation for æternity nodes

Infrastructure is automatically created and managed by Ansible playbooks run by CircleCI.
Only changes to master branch are deployed.
Infrastructure is orchestrated with [Terraform](https://www.terraform.io).
Ansible playbooks are run against [dynamic host inventories](http://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html).

Below documentation is meant for manual testing and additional details. It's already integrated in CircleCI workflow.

## Requirements

The only requirement is Docker. All the libraries and packages are built in the docker image.
If for some reason one needs to setup the requirements on the host system see the Dockerfile.

## Credentials setup

### Amazon Web Services

Yous should make sure [AWS CommandLine interface credentials are set](http://docs.ansible.com/ansible/latest/intro_dynamic_inventory.html#example-aws-ec2-external-inventory-script)
either by environment variables or `~/.aws/credentials` file.

If you have configured multiple AWS credentials you can pass AWS_PROFILE variable before the commands:

```bash
AWS_PROFILE=aeternity ansible-inventory --list
```

### Secrets

Secrets are managed with [Hashicorp Vault](https://www.vaultproject.io).

The Vault server address can be set with `VAULT_ADDR` environment variable.

An operator may authenticate with [GitHub personal token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/#creating-a-token)
as `VAULT_GITHUB_TOKEN` environment variable. Any valid GitHub access token with the read:org scope can be used for authentication.

Applications and services may authenticate with `VAULT_ROLE_ID` and `VAULT_SECRET_ID` environment variables.

Vault token could be used by setting `VAULT_AUTH_TOKEN` environment variable (translates to `VAULT_TOKEN` by docker entry point). `VAULT_AUTH_TOKEN` is highest priority compared to other credentials.

## Docker image

A Docker image `aeternity/infrastructure` is build and published to DockerHub. To use the image one should configure all the required credentials as documented above and run the container:

```bash
docker run -it --env-file env.list aeternity/infrastructure
```

### SSH

According to the Vault authentication token permissions, one can ssh to any node they have access to by running:

```
make ssh HOST=192.168.1.1
```

This is a shorthand target the actually run `ssh-epoch`.
Note the `ssh-%` target suffix, it could be any supported node username, e.g. `ssh-master`.

## Ansible playbooks

### Ansible dynamic inventory

Check that your AWS credentials are setup and dynamic inventory is working as excepted:
```bash
cd ansible && ansible-inventory --list
```

### List inventory

Get a grouped list of ansible inventory

```
make list-inventory
```

Inventory data is stored in local file `ansible/inventory-list.json`. To refresh it later you can `make dump-inventory`

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

To deploy epoch package run:
```bash
export PACKAGE=https://github.com/aeternity/epoch/releases/download/v0.17.0/epoch-0.17.0-ubuntu-x86_64.tar.gz
make deploy DEPLOY_ENV=integration
```

Additional parameters:
- DEPLOY_DOWNTIME - schedule a downtime period to mute monitoring alerts
- DEPLOY_COLOR - some environments might be colored to enable blue/green deployments
- DEPLOY_DB_VERSION - chain db directory suffix that can be bumped to purge the old db

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
