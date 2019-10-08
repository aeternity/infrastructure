.DEFAULT_GOAL := lint
DEPLOY_DOWNTIME ?= 0
ROLLING_UPDATE ?= 100%
BACKUP_SUFFIX ?= backup
TF_LOCK_TIMEOUT=5m
VAULT_TOKENS_TTL ?= 4h
SEED_CHECK_ENVS = main uat next
SECRETS_OUTPUT_DIR ?= /tmp/secrets
ENV = envdir $(SECRETS_OUTPUT_DIR)
VAULT_ADDR ?= $(AE_VAULT_ADDR)
TF_COMMON_PARAMS = -var vault_addr=$(VAULT_ADDR) -lock-timeout=$(TF_LOCK_TIMEOUT) -parallelism=20
CONFIG_OUTPUT_DIR ?= /tmp/config
VAULT_CONFIG_ROOT ?= secret/aenode/config
NODE_CONFIG ?= /tmp/node_config.yml

$(SECRETS_OUTPUT_DIR): scripts/secrets/dump.sh
	@SECRETS_OUTPUT_DIR=$(SECRETS_OUTPUT_DIR) scripts/secrets/dump.sh

secrets: $(SECRETS_OUTPUT_DIR)

envshell: secrets
	@envshell $(SECRETS_OUTPUT_DIR)

setup-node: check-deploy-env secrets
	cd ansible && $(ENV) ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e vault_addr=$(VAULT_ADDR) \
		-e env=$(DEPLOY_ENV) \
		setup.yml

setup-monitoring: check-deploy-env secrets
	cd ansible && $(ENV) ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/var/venv/bin/python \
		-e env=$(DEPLOY_ENV) \
		monitoring.yml

setup: setup-node setup-monitoring

deploy: check-deploy-env secrets
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

	cd ansible && $(ENV) ansible-playbook \
		--limit="$(LIMIT)" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e package=$(PACKAGE) \
		-e env=$(DEPLOY_ENV) \
		-e downtime=$(DEPLOY_DOWNTIME) \
		-e db_version=$(DEPLOY_DB_VERSION) \
		-e rolling_update="${ROLLING_UPDATE}" \
		deploy.yml

manage-node: check-deploy-env secrets
ifndef CMD
	$(error CMD is undefined, supported commands: start, stop, restart, ping)
endif
	cd ansible && $(ENV) ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e env=$(DEPLOY_ENV) \
		-e db_version=0 \
		-e cmd=$(CMD) \
		manage-node.yml

reset-net: check-deploy-env secrets
	cd ansible && $(ENV) ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		reset-net.yml

mnesia_snapshot: secrets
ifeq ($(BACKUP_DB_VERSION),)
	$(error BACKUP_DB_VERSION should be provided)
endif
ifeq ($(BACKUP_ENV),)
	$(error BACKUP_ENV should be provided)
endif
	cd ansible && $(ENV) ansible-playbook \
		--limit="tag_role_aenode:&tag_env_$(BACKUP_ENV)" \
		-e ansible_python_interpreter=/var/venv/bin/python \
		-e snapshot_suffix=$(BACKUP_SUFFIX) \
		-e db_version=$(BACKUP_DB_VERSION) \
		-e env=$(BACKUP_ENV) \
		mnesia_snapshot.yml

ebs-grow-volume: check-deploy-env secrets
	$(eval LIMIT=tag_role_aenode:&tag_env_$(DEPLOY_ENV))
ifneq ($(DEPLOY_REGION),)
	$(eval LIMIT=$(LIMIT):&region_$(DEPLOY_REGION))
endif
	cd ansible && $(ENV) ansible-playbook --limit="$(LIMIT)" \
		-e ansible_python_interpreter=/var/venv/bin/python \
		-e env=$(DEPLOY_ENV) \
		-e vault_addr=$(VAULT_ADDR) \
		ebs-grow-volume.yml

provision: check-deploy-env secrets
	cd ansible && $(ENV) ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e env=$(DEPLOY_ENV) \
		-e vault_addr=$(VAULT_ADDR) \
		-e package=$(PACKAGE) \
		-e bootstrap_version=$(BOOTSTRAP_VERSION) \
		async_provision.yml

~/.ssh/id_ae_infra_ed25519:
	@ssh-keygen -t ed25519 -N "" -f $@

.PRECIOUS: ~/.ssh/id_ae_infra_ed25519-%-cert.pub
~/.ssh/id_ae_infra_ed25519-%-cert.pub: ~/.ssh/id_ae_infra_ed25519 secrets
	@$(ENV) vault write -field=signed_key ssh/sign/$* ttl=$(VAULT_TOKENS_TTL) public_key=@$<.pub > $@

cert-%: ~/.ssh/id_ae_infra_ed25519-%-cert.pub
	@

cert: cert-aeternity

ssh-%: cert-%
	@ssh $*@$(HOST)

ssh: ssh-aeternity

integration-tests-run: secrets
	cd test/terraform && terraform init
	cd test/terraform && $(ENV) terraform apply $(TF_COMMON_PARAMS) --auto-approve
	# TODO this is actually a smoke test that can be migrated to "goss"
	cd ansible && $(ENV) ansible-playbook \
		--limit=tag_envid_$(TF_VAR_envid) \
		-e "@vars/aeternity/test.yml" \
		-e env=test \
		health-check.yml

health-check-env-local: secrets
	cd ansible && $(ENV) ansible-playbook \
		--limit=tag_env_$(DEPLOY_ENV) \
		-e "@vars/aeternity/$(DEPLOY_ENV).yml" \
		-e env=$(DEPLOY_ENV) \
		health-check.yml

integration-tests-cleanup: secrets
	cd test/terraform && $(ENV) terraform destroy $(TF_COMMON_PARAMS) --auto-approve

integration-tests: integration-tests-run integration-tests-cleanup

lint-ansible:
	ansible-lint ansible/*.yml --exclude ~/.ansible/roles

lint: lint-ansible

test/goss/remote/vars/seed-peers-%.yaml: secrets ansible/inventory-list.json
	cat ansible/inventory-list.json | $(ENV) python3 ansible/scripts/dump-seed-peers-keys.py --env $* > $@

check-seed-peers-%: test/goss/remote/vars/seed-peers-%.yaml
	goss -g test/goss/remote/group-peer-keys.yaml --vars $< validate

check-seed-peers-all: $(addprefix check-seed-peers-, $(SEED_CHECK_ENVS))

check-deploy-env:
ifndef DEPLOY_ENV
	$(error DEPLOY_ENV is undefined)
endif

ansible/inventory-list.json: secrets
	cd ansible && $(ENV) ansible-inventory --list > inventory-list.json

list-inventory: ansible/inventory-list.json
	cat ansible/inventory-list.json | ansible/scripts/dump_inventory.py

health-check-%: ansible/inventory-list.json
	ANSIBLE_TAG=tag_env_$* REGION=$(AWS_REGION) \
	goss -g test/goss/remote/group-health.yaml --vars ansible/inventory-list.json validate

health-check-node:
	goss -g test/goss/remote/node-health.yaml validate

health-check-all: ansible/inventory-list.json
	REGION=$(AWS_REGION) \
	goss -g test/goss/remote/group-health.yaml --vars ansible/inventory-list.json validate

clean:
	rm -f ~/.ssh/id_ae_infra*
	rm -f ansible/inventory-list.json
	rm -rf $(SECRETS_OUTPUT_DIR)
	rm -rf $(CONFIG_OUTPUT_DIR)

$(CONFIG_OUTPUT_DIR): secrets
	@mkdir -p $(CONFIG_OUTPUT_DIR)

vault-configs-list: $(CONFIG_OUTPUT_DIR)
	@$(ENV) vault list $(VAULT_CONFIG_ROOT) | tail -n +3

vault-configs-dump: $(CONFIG_OUTPUT_DIR)
	### Dump all configs
	@$(ENV) vault list $(VAULT_CONFIG_ROOT) | tail -n +3 | xargs -IENV make --no-print-directory $(CONFIG_OUTPUT_DIR)/ENV.yml

vault-config-%: $(CONFIG_OUTPUT_DIR) $(CONFIG_OUTPUT_DIR)/%.yml ;

vault-show-%: vault-config-%
	@cat $(CONFIG_OUTPUT_DIR)/$*.yml

node-config-%: vault-config-%
	cp $(CONFIG_OUTPUT_DIR)/$*.yml $(NODE_CONFIG)

.PRECIOUS: $(CONFIG_OUTPUT_DIR)/%.yml
$(CONFIG_OUTPUT_DIR)/%.yml:
	### - $(CONFIG_OUTPUT_DIR)/$*.yml
	@$(ENV) vault kv get -field=node_config $(VAULT_CONFIG_ROOT)/$* > $(CONFIG_OUTPUT_DIR)/$*.yml

# List of all available targets
.PHONY help: ; @$(MAKE) -pq | awk '/^[^.%][-A-Za-z0-9_%*]*:/{ print substr($$1, 1, length($$1)-1) }' | sort -u

.PHONY: \
	secrets images setup-node setup-monitoring setup \
	manage-node reset-net lint cert-% ssh-% ssh clean \
	check-seed-peers check-deploy-env list-inventory \
	check-seed-peers-% check-seed-peers-all \
	health-check-node health-check-% health-check-all \
	vault-config-clean vault-config-all
