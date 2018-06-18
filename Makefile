SITE_PACKAGES := $(shell python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
VIRTUAL_ENV_ERR = Python Virtual environment is not active. Run `virtualenv -p python3 .venv/py3 && source .venv/py3/bin/activate`

all: ansible/roles

$(SITE_PACKAGES): requirements.txt
ifndef VIRTUAL_ENV
	$(error $(VIRTUAL_ENV_ERR))
endif
	pip install -r requirements.txt
	touch $(SITE_PACKAGES)

pip: $(SITE_PACKAGES)

ansible/roles: pip
	cd ansible && ansible-galaxy install -r requirements.yml -p roles
	touch ansible/roles

images: ansible/roles
	packer build packer/epoch.json

setup-infrastructure-terraform:
	cd terraform &&  && terraform init && teraform apply --auto-approve -e "env=dev3"

setup-infrastructure: ansible/roles check-deploy-env
	cd ansible && ansible-playbook -e 'ansible_python_interpreter="/usr/bin/env python"' \
		--tags "$(DEPLOY_ENV)" environments.yml

setup-node: ansible/roles check-deploy-env
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" setup.yml

setup-monitoring: ansible/roles check-deploy-env
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" monitoring.yml

setup: setup-infrastructure setup-node setup-monitoring

manage-node: ansible/roles check-deploy-env
ifndef CMD
	$(error CMD is undefined, supported commands: start, stop, restart, ping)
endif
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" \
		--extra-vars="cmd=$(CMD)" manage-node.yml

reset-net: ansible/roles check-deploy-env
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" reset-net.yml

test-openstack: pip
	openstack stack create test -e openstack/test/create.yml \
		-t openstack/ae-environment.yml --enable-rollback --wait --dry-run

test-setup-environments: pip
	cd terraform && terraform init && terraform plan
#	cd ansible && ansible-playbook -e 'ansible_python_interpreter="/usr/bin/env python"' \
#		--check -i localhost, environments.yml

lint:
	ansible-lint ansible/setup.yml
	ansible-lint ansible/monitoring.yml --exclude ansible/roles
	ansible-lint ansible/manage-node.yml
	ansible-lint ansible/reset-net.yml
	packer validate packer/epoch.json

check-deploy-env:
ifndef DEPLOY_ENV
	$(error DEPLOY_ENV is undefined)
endif

clean:
	rm -rf ansible/roles
ifdef VIRTUAL_ENV
	$(info Don't forget to deactivate virtualenv by calling `deactivate` bash function)
endif

.PHONY: \
	all pip \
	images setup-infrastructure setup-node setup-monitoring setup \
	manage-node reset-net lint test-openstack test-setup-environments \
	check-deploy-env clean
