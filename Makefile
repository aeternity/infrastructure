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
VAULT_CONFIG_FIELD ?= node_config
LIST_CONFIG_ENVS := $(ENV) vault list $(VAULT_CONFIG_ROOT) | tail -n +3
CONFIG_ENV ?= $(DEPLOY_ENV)
LIMIT ?= tag_env_$(DEPLOY_ENV):&tag_role_aenode
PYTHON ?= /usr/bin/python3
DEPLOY_DB_VERSION ?= 1

ANSIBLE_EXTRA_VARS =
ANSIBLE_EXTRA_PARAMS ?=

$(SECRETS_OUTPUT_DIR): scripts/secrets/dump.sh
	@SECRETS_OUTPUT_DIR=$(SECRETS_OUTPUT_DIR) scripts/secrets/dump.sh

secrets: $(SECRETS_OUTPUT_DIR)

envshell: secrets
	@envshell $(SECRETS_OUTPUT_DIR)

# ansible playbooks
ansible/%.yml: secrets $(CONFIG_OUTPUT_DIR)/$(CONFIG_ENV).yml
	cd ansible && $(ENV) ansible-playbook \
		--limit="$(LIMIT)" \
		-e ansible_python_interpreter=$(PYTHON) \
		-e env=$(DEPLOY_ENV) \
		-e "@$(CONFIG_OUTPUT_DIR)/$(CONFIG_ENV).yml" \
		-e db_version=$(DEPLOY_DB_VERSION) \
		$(ANSIBLE_EXTRA_VARS) \
		$(ANSIBLE_EXTRA_PARAMS) \
		$*.yml

# playbook specifics

ansible/setup.yml: ANSIBLE_EXTRA_VARS=-e vault_addr="$(VAULT_ADDR)"

ansible/monitoring.yml: PYTHON=/var/venv/bin/python

ansible/deploy.yml:
ifeq ($(DEPLOY_ENV),)
	$(error DEPLOY_ENV should be provided)
endif

ansible/deploy.yml: LIMIT=tag_role_aenode:&tag_env_$(DEPLOY_ENV)
ansible/deploy.yml: LIMIT:=$(if $(DEPLOY_COLOR),$(LIMIT):&tag_color_$(DEPLOY_COLOR),$(LIMIT))
ansible/deploy.yml: LIMIT:=$(if $(DEPLOY_KIND),$(LIMIT):&tag_kind_$(DEPLOY_KIND),$(LIMIT))
ansible/deploy.yml: LIMIT:=$(if $(DEPLOY_REGION),$(LIMIT):&region_$(DEPLOY_REGION),$(LIMIT))
ansible/deploy.yml: ANSIBLE_EXTRA_VARS=\
	-e package="$(PACKAGE)" \
	-e downtime="$(DEPLOY_DOWNTIME)" \
	-e rolling_update="$(ROLLING_UPDATE)" \

ansible/manage-node.yml:
ifndef CMD
	$(error CMD is undefined, supported commands: start, stop, restart, ping)
endif

ansible/manage-node.yml: ANSIBLE_EXTRA_VARS=-e cmd=$(CMD)

ansible/mnesia_snapshot.yml:
ifeq ($(BACKUP_ENV),)
	$(error BACKUP_ENV should be provided)
endif
ansible/mnesia_snapshot.yml: LIMIT=tag_role_aenode:&tag_env_$(BACKUP_ENV)
ansible/mnesia_snapshot.yml: PYTHON=/var/venv/bin/python
ansible/mnesia_snapshot.yml: ANSIBLE_EXTRA_VARS=-e snapshot_suffix="$(BACKUP_SUFFIX)"

ansible/ebs-grow-volume.yml: ANSIBLE_EXTRA_VARS=-e vault_addr="$(VAULT_ADDR)"
ansible/ebs-grow-volume.yml: PYTHON=/var/venv/bin/python
ansible/ebs-grow-volume.yml: LIMIT:=$(if $(DEPLOY_REGION),$(LIMIT):$region_$(DEPLOY_REGION))

ansible/async_provision.yml: ANSIBLE_EXTRA_VARS= \
	-e vault_addr="$(VAULT_ADDR)" \
	-e package="$(PACKAGE)" \
	-e bootstrap_version="$(BOOTSTRAP_VERSION)" \

ansible/health-check.yml: LIMIT=tag_env_$(DEPLOY_ENV)

# ansible playbook aliases
health-check-env-local: ansible/health-check.yml
provision: ansible/async_provision.yml
ebs-grow-volume: ansible/ebs-grow-volume.yml
reset-net: ansible/reset-net.yml
manage-node: ansible/manage-node.yml
setup-monitoring: ansible/monitoring.yml
setup-node: ansible/setup.yml
deploy: ansible/deploy.yml
mnesia_snapshot: ansible/mnesia_snapshot.yml
setup: setup-node setup-monitoring

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

integration-tests-run: secrets vault-config-test
	cd test/terraform && terraform init
	cd test/terraform && $(ENV) terraform apply $(TF_COMMON_PARAMS) --auto-approve
	# TODO this is actually a smoke test that can be migrated to "goss"
	cd ansible && $(ENV) ansible-playbook \
		--limit=tag_envid_$(TF_VAR_envid) \
		-e env=test \
		-e "@$(CONFIG_OUTPUT_DIR)/test.yml" \
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

# Vault config
$(CONFIG_OUTPUT_DIR):
	@mkdir -p $(CONFIG_OUTPUT_DIR)

vault-configs-list: secrets
	@$(LIST_CONFIG_ENVS)

vault-configs-dump: secrets
	@$(MAKE) --no-print-directory $(addprefix vault-config-, $(shell $(LIST_CONFIG_ENVS)))

vault-config-% : $(CONFIG_OUTPUT_DIR)/%.yml ;

.PRECIOUS: $(CONFIG_OUTPUT_DIR)/%.yml
$(CONFIG_OUTPUT_DIR)/%.yml: YML=$(CONFIG_OUTPUT_DIR)/$*.yml
$(CONFIG_OUTPUT_DIR)/%.yml: secrets $(CONFIG_OUTPUT_DIR)
	@($(ENV) vault read -field=$(VAULT_CONFIG_FIELD) $(VAULT_CONFIG_ROOT)/$* > $(YML) && echo $(YML) ) || rm $(YML)

# List of all available targets
.PHONY help:
	@$(MAKE) vault-configs-dump -pq | awk '/^[^.%][-A-Za-z0-9_@]*:/{ print substr($$1, 1, length($$1)-1) }' | sort -u

.PHONY: \
	secrets images setup-node setup-monitoring setup \
	manage-node reset-net lint cert-% ssh-% ssh clean \
	check-seed-peers list-inventory \
	check-seed-peers-% check-seed-peers-all \
	health-check-node health-check-% health-check-all \
	ansible/%.yml
