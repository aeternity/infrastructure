.DEFAULT_GOAL := lint
DEPLOY_DOWNTIME ?= 0
ROLLING_UPDATE ?= 100%
BACKUP_SUFFIX ?= backup
BACKUP_DIR ?= /tmp/mnesia_backups
TF_LOCK_TIMEOUT=5m
VAULT_TOKENS_TTL ?= 4h
SEED_CHECK_ENVS = main uat next

check-terraform-changes-environments:
	cd terraform/environments && terraform init -lock-timeout=$(TF_LOCK_TIMEOUT)
	cd terraform/environments && terraform plan -lock-timeout=$(TF_LOCK_TIMEOUT) -detailed-exitcode

check-terraform-changes-gateway:
	cd terraform/gateway && terraform init -lock-timeout=$(TF_LOCK_TIMEOUT)
	cd terraform/gateway && terraform plan -lock-timeout=$(TF_LOCK_TIMEOUT) -detailed-exitcode

check-terraform-changes: check-terraform-changes-environments check-terraform-changes-gateway

setup-terraform-environments:
	cd terraform/environments && terraform init -lock-timeout=$(TF_LOCK_TIMEOUT)
	cd terraform/environments && terraform apply -lock-timeout=$(TF_LOCK_TIMEOUT) --auto-approve

setup-terraform-gatewway:
	cd terraform/gateway && terraform init -lock-timeout=$(TF_LOCK_TIMEOUT)
	cd terraform/gateway && terraform apply -lock-timeout=$(TF_LOCK_TIMEOUT) --auto-approve

setup-terraform: setup-terraform-environments setup-terraform-gatewway

setup-node: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e vault_addr=$(VAULT_ADDR) \
		-e env=$(DEPLOY_ENV) \
		setup.yml

setup-monitoring: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/var/venv/bin/python \
		-e env=$(DEPLOY_ENV) \
		monitoring.yml

setup: setup-node setup-monitoring

deploy: check-deploy-env
ifeq ($(DEPLOY_DB_VERSION),)
	$(error DEPLOY_DB_VERSION should be provided)
endif
	$(eval LIMIT=tag_role_aenode:&tag_env_$(DEPLOY_ENV))
ifneq ($(DEPLOY_COLOR),)
	$(eval LIMIT=$(LIMIT):&tag_color_$(DEPLOY_COLOR))
endif
ifneq ($(DEPLOY_KIND),)
	$(eval LIMIT=$(LIMIT):&tag_kind_$(DEPLOY_KIND))
endif
ifneq ($(DEPLOY_REGION),)
	$(eval LIMIT=$(LIMIT):&region_$(DEPLOY_REGION))
endif

	cd ansible && ansible-playbook \
		--limit="$(LIMIT)" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e package=$(PACKAGE) \
		-e hosts_group=tag_env_$(DEPLOY_ENV) \
		-e env=$(DEPLOY_ENV) \
		-e downtime=$(DEPLOY_DOWNTIME) \
		-e db_version=$(DEPLOY_DB_VERSION) \
		-e rolling_update="${ROLLING_UPDATE}" \
		deploy.yml

attach: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e env=$(DEPLOY_ENV) \
		-e db_version=0 \
		attach.yml

migrate: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e env=$(DEPLOY_ENV) \
		migrate-storage.yml

manage-node: check-deploy-env
ifndef CMD
	$(error CMD is undefined, supported commands: start, stop, restart, ping)
endif
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e env=$(DEPLOY_ENV) \
		-e db_version=0 \
		-e cmd=$(CMD) \
		manage-node.yml

reset-net: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		reset-net.yml

mnesia_snapshot:
ifeq ($(BACKUP_DB_VERSION),)
	$(error BACKUP_DB_VERSION should be provided)
endif
ifeq ($(BACKUP_ENV),)
	$(error BACKUP_ENV should be provided)
endif
	cd ansible && ansible-playbook \
		--limit="tag_role_aenode:&tag_env_$(BACKUP_ENV)" \
		-e ansible_python_interpreter=/var/venv/bin/python \
		-e download_dir=$(BACKUP_DIR) \
		-e backup_suffix=$(BACKUP_SUFFIX) \
		-e db_version=$(BACKUP_DB_VERSION) \
		-e env=$(BACKUP_ENV) \
		mnesia_snapshot.yml

provision: check-deploy-env
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
	-e ansible_python_interpreter=/usr/bin/python3 \
	-e env=$(DEPLOY_ENV) \
	-e vault_addr=$(VAULT_ADDR) \
	-e package=$(PACKAGE) \
	-e bootstrap_version=$(BOOTSTRAP_VERSION) \
	async_provision.yml

~/.ssh/id_ae_infra_ed25519:
	@ssh-keygen -t ed25519 -N "" -f $@

.PRECIOUS: ~/.ssh/id_ae_infra_ed25519-%-cert.pub
~/.ssh/id_ae_infra_ed25519-%-cert.pub: ~/.ssh/id_ae_infra_ed25519
	@vault write -field=signed_key ssh/sign/$* ttl=$(VAULT_TOKENS_TTL) public_key=@$<.pub > $@

cert-%: ~/.ssh/id_ae_infra_ed25519-%-cert.pub
	@

cert: cert-aeternity

ssh-%: cert-%
	@ssh $*@$(HOST)

ssh: ssh-aeternity

# TODO also add ansible idempotent tests here
unit-tests:
	cd terraform/environments && terraform init -lock-timeout=$(TF_LOCK_TIMEOUT)
	cd terraform/environments && terraform plan -lock-timeout=$(TF_LOCK_TIMEOUT)

integration-tests-run:
	cd test/terraform && terraform init
	cd test/terraform && terraform apply --auto-approve
	# TODO this is actually a smoke test that can be migrated to "goss"
	cd ansible && ansible-playbook health-check.yml --limit=tag_envid_$(TF_VAR_envid) -e env=test

health-check-env-local:
	cd ansible && ansible-playbook health-check.yml --limit=tag_env_$(DEPLOY_ENV) \
	-e env=$(DEPLOY_ENV) \

integration-tests-cleanup:
	cd test/terraform && terraform destroy --auto-approve

integration-tests: integration-tests-run integration-tests-cleanup

lint-ansible:
	ansible-lint ansible/*.yml --exclude ~/.ansible/roles

terraform-validate-environments:
	cd terraform/environments && terraform init && terraform validate && terraform fmt -check=true -diff=true

terraform-validate-gateway:
	cd terraform/gateway && terraform init && terraform validate && terraform fmt -check=true -diff=true

terraform-validate: terraform-validate-environments terraform-validate-gateway

lint: lint-ansible terraform-validate

test/goss/remote/vars/seed-peers-%.yaml: ansible/inventory-list.json
	cat ansible/inventory-list.json | python3 ansible/scripts/dump-seed-peers-keys.py --env $* > $@

check-seed-peers-%: test/goss/remote/vars/seed-peers-%.yaml
	goss -g test/goss/remote/check-seed-peers.yaml --vars $< validate

check-seed-peers-all: $(addprefix check-seed-peers-, $(SEED_CHECK_ENVS))

check-deploy-env:
ifndef DEPLOY_ENV
	$(error DEPLOY_ENV is undefined)
endif

ansible/inventory-list.json:
	cd ansible && ansible-inventory --list > inventory-list.json

list-inventory: ansible/inventory-list.json
	cat ansible/inventory-list.json | ansible/scripts/dump_inventory.py

health-check-%: ansible/inventory-list.json
	ANSIBLE_TAG=tag_env_$* REGION=$(AWS_REGION) \
	goss -g test/goss/remote/peers-health-check.yaml --vars ansible/inventory-list.json validate

health-check-node:
	goss -g test/goss/remote/health-check-node.yaml validate

health-check-all: ansible/inventory-list.json
	REGION=$(AWS_REGION) \
	goss -g test/goss/remote/peers-health-check.yaml --vars ansible/inventory-list.json validate

clean:
	rm ~/.ssh/id_ae_infra*
	rm -f ansible/inventory-list.json

.PHONY: \
	images setup-terraform setup-node setup-monitoring setup \
	setup-terraform-gatewway setup-terraform-environments \
	manage-node reset-net lint cert-% ssh-% ssh clean \
	check-seed-peers check-deploy-env list-inventory \
	check-seed-peers-% check-seed-peers-all \
	health-check-node health-check-% health-check-all
