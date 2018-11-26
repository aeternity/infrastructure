.DEFAULT_GOAL := lint
DEPLOY_DOWNTIME ?= 0
BACKUP_SUFFIX ?= backup
BACKUP_DIR ?= /tmp/mnesia_backups

setup-terraform:
	cd terraform && terraform init && terraform apply --auto-approve

setup-node: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e vault_addr=$(VAULT_ADDR) \
		setup.yml

setup-monitoring: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" \
		-e ansible_python_interpreter=/var/venv/bin/python \
		-e env=$(DEPLOY_ENV) \
		monitoring.yml

setup: setup-node setup-monitoring

deploy: check-deploy-env
ifeq ($(DEPLOY_DB_VERSION),)
	$(error DEPLOY_DB_VERSION should be provided)
endif
	$(eval LIMIT=tag_role_epoch:&tag_env_$(DEPLOY_ENV))
ifneq ($(DEPLOY_COLOR),)
	$(eval LIMIT=$(LIMIT):&tag_color_$(DEPLOY_COLOR))
endif
	cd ansible && ansible-playbook \
		--limit="$(LIMIT)" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e package=$(PACKAGE) \
		-e hosts_group=tag_env_$(DEPLOY_ENV) \
		-e env=$(DEPLOY_ENV) \
		-e downtime=$(DEPLOY_DOWNTIME) \
		-e db_version=$(DEPLOY_DB_VERSION) \
		deploy.yml

manage-node: check-deploy-env
ifndef CMD
	$(error CMD is undefined, supported commands: start, stop, restart, ping)
endif
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e env=$(DEPLOY_ENV) \
		-e db_version=0 \
		-e cmd=$(CMD) \
		manage-node.yml

reset-net: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		reset-net.yml

mnesia_backup:
	cd ansible && ansible-playbook \
		--limit="tag_role_epoch:&tag_env_$(BACKUP_ENV)" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e download_dir=$(BACKUP_DIR) \
		-e backup_suffix=$(BACKUP_SUFFIX) \
		mnesia_backup.yml

~/.ssh/id_ae_infra_ed25519:
	@ssh-keygen -t ed25519 -N "" -f $@

.PRECIOUS: ~/.ssh/id_ae_infra_ed25519-%-cert.pub
~/.ssh/id_ae_infra_ed25519-%-cert.pub: ~/.ssh/id_ae_infra_ed25519
	@vault write -field=signed_key ssh/sign/$* public_key=@$<.pub > $@

cert-%: ~/.ssh/id_ae_infra_ed25519-%-cert.pub
	@

ssh-%: cert-%
	@ssh $*@$(HOST)

ssh: ssh-epoch

test-setup-environments:
	cd terraform && terraform init && terraform plan

lint:
	ansible-lint ansible/setup.yml --exclude ~/.ansible/roles
	ansible-lint ansible/monitoring.yml --exclude ~/.ansible/roles
	ansible-lint ansible/manage-node.yml
	ansible-lint ansible/reset-net.yml
	cd terraform && terraform init && terraform validate && terraform fmt -check=true -diff=true

# Keep in sync from https://github.com/aeternity/epoch/blob/master/config/sys.config
check-seed-peers:
	curl -fs -m 5 http://52.10.46.160:3013/v2/peers/pubkey | grep -q 'QU9CvhAQH56a2kA15tCnWPRJ2srMJW8ZmfbbFTAy7eG4o16Bf'
	curl -fs -m 5 http://18.195.109.60:3013/v2/peers/pubkey | grep -q '2vhFb3HtHd1S7ynbpbFnEdph1tnDXFSfu4NGtq46S2eM5HCdbC'
	curl -fs -m 5 http://13.250.162.250:3013/v2/peers/pubkey | grep -q '27xmgQ4N1E3QwHyoutLtZsHW5DSW4zneQJ3CxT5JbUejxtFuAu'
	curl -fs -m 5 http://18.130.148.7:3013/v2/peers/pubkey | grep -q 'nt5N7fwae3DW8Mqk4kxkGAnbykRDpEZq9dzzianiMMPo4fJV7'
	curl -fs -m 5 http://52.220.198.72:3013/v2/peers/pubkey | grep -q '2gPZjuPnJnTVEbrB9Qgv7f4MdhM4Jh6PD22mB2iBA1g7FRvHTk'
	curl -fs -m 5 http://52.11.110.179:3013/v2/peers/pubkey | grep -q 'RKVZjm7UKPLGvyKWqVZN1pXN6CTCxfmYz2HkNL2xiAhLVd2ho'
	curl -fs -m 5 http://35.177.192.219:3013/v2/peers/pubkey | grep -q '2KWhoNRdythXAmgCbM6QxFo95WM4XXGq2pjcbKitXFpUHnPQc3'

check-deploy-env:
ifndef DEPLOY_ENV
	$(error DEPLOY_ENV is undefined)
endif

clean:
	rm ~/.ssh/id_ae_infra*

.PHONY: \
	images setup-terraform setup-node setup-monitoring setup \
	manage-node reset-net lint cert-% ssh-% ssh clean \
	check-seed-peers check-deploy-env
