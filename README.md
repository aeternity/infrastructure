# Infrastructure management automation for æternity nodes

Infrastructure is automatically managed by Ansible playbooks run by Travis.
When some changes are merged to master, after successful Travis build the changes are deployed to the infrastructure.

## Ansible Deploy

Below documentation is meant for manual testing and additional details. It's already integrated in Travis workflow.

This implementation supports OpenStack dynamic inventory by using [Ansible 2.4 OpenStack inventory plugin](https://docs.ansible.com/ansible/devel/plugins/inventory/openstack.html).
To install it's dependencies with `pip`:
```bash
pip install -r requirements.txt
```

You should make sure [OpenStack credentials are set](https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#environment-variables)
either by environment variables or clouds.yml file.

```bash
source ~/my/secrets/openstack.rc
ansible-inventory -i inventory/openstack.yml --list
```

Setup of the infrastructure by running:
```bash
cd ansible && ansible-playbook setup.yml"
```
