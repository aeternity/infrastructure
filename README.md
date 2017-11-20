# Infrastructure management automation for æternity nodes

Infrastructure is automatically created and managed by Ansible playbooks run by Travis.
Only changes to master branch are deployed.
Infrastructure is orchestrated with [OpenStack Heat](https://docs.openstack.org/heat/latest/).
Setup playbook is run against dynamic hosts list handled by Ansible OpenStack plugin.

Below documentation is meant for manual testing and additional details. It's already integrated in Travis workflow.

## Dependencies
This implementation is using Ansible and it's [Ansible 2.4 OpenStack inventory plugin](https://docs.ansible.com/ansible/devel/plugins/inventory/openstack.html).
To install dependencies use `pip`:
```bash
pip install -r requirements.txt
```

## Credentials setup

You should make sure [OpenStack credentials are set](https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#environment-variables)
either by environment variables or clouds.yml file.

```bash
source ~/my/secrets/openstack.rc
```

## Infrastructure orchestration
New environment stacks can be created by running:
```bash
openstack stack create my-env -t openstack/ae-environment.yml --parameter "environment=my_env"
```

Also already running environment can be updated by:
```bash
openstack stack update my-env -t openstack/ae-environment.yml --parameter "environment=my_env"
```

## Ansible Deploy

Check that your OpenStack credentials are setup and dynamic inventory is working as excepted:
```bash
ansible-inventory -i inventory/openstack.yml --list
```

Setup environments infrastructure by running:
```bash
cd ansible
ansible-playbook environemnts.yml
ansible-playbook setup.yml
```
