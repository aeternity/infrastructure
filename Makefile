.DEFAULT_GOAL := lint
DEPLOY_DOWNTIME ?= 0
BACKUP_SUFFIX ?= backup
BACKUP_DIR ?= /tmp/mnesia_backups

images:
	packer build packer/epoch.json
	python packer/cleanup-ami-and-snapshots.py

setup-infrastructure: check-deploy-env
	cd ansible && ansible-playbook --tags "$(DEPLOY_ENV)" environments.yml

setup-terraform:
	cd terraform && terraform init && terraform apply --auto-approve

setup-node: check-deploy-env
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" setup.yml

setup-monitoring: check-deploy-env
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" monitoring.yml

setup: setup-infrastructure setup-node setup-monitoring

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
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" \
		--extra-vars="cmd=$(CMD)" manage-node.yml

reset-net: check-deploy-env
	cd ansible && ansible-playbook --limit="tag_env_$(DEPLOY_ENV):&tag_role_epoch" reset-net.yml

mnesia_backup:
	cd ansible && ansible-playbook \
		--limit="tag_role_epoch:&tag_env_$(BACKUP_ENV)" \
		-e download_dir=$(BACKUP_DIR) \
		-e backup_suffix=$(BACKUP_SUFFIX) \
		mnesia_backup.yml

test-openstack:
	openstack stack create test -e openstack/test/create.yml \
		-t openstack/ae-environment.yml --enable-rollback --wait --dry-run

test-setup-environments:
	cd ansible && ansible-playbook --check -i localhost, environments.yml
	cd terraform && terraform init && terraform plan

lint:
	ansible-lint ansible/setup.yml
	ansible-lint ansible/monitoring.yml --exclude ~/.ansible/roles
	ansible-lint ansible/manage-node.yml
	ansible-lint ansible/reset-net.yml
	packer validate packer/epoch.json
	cd terraform && terraform init && terraform validate && terraform fmt -check=true -diff=true

# Keep in sync from https://github.com/aeternity/epoch/blob/master/config/sys.config
check-seed-peers:
	curl -fs -m 5 http://52.10.46.160:3013/v2/peer/key | grep -q 'QU9CvhAQH56a2kA15tCnWPRJ2srMJW8ZmfbbFTAy7eG4o16Bf'
	curl -fs -m 5 http://18.195.109.60:3013/v2/peer/key | grep -q '2vhFb3HtHd1S7ynbpbFnEdph1tnDXFSfu4NGtq46S2eM5HCdbC'
	curl -fs -m 5 http://13.250.162.250:3013/v2/peer/key | grep -q '27xmgQ4N1E3QwHyoutLtZsHW5DSW4zneQJ3CxT5JbUejxtFuAu'
	curl -fs -m 5 http://31.13.249.70:3013/v2/peer/key | grep -q '2i8N6XsjCGe1wkdMhDRs7t7xzijrjJDN4xA22RoNGCgt6ay9QB'

check-deploy-env:
ifndef DEPLOY_ENV
	$(error DEPLOY_ENV is undefined)
endif

.PHONY: \
	images setup-infrastructure setup-terraform setup-node setup-monitoring setup \
	manage-node reset-net lint test-openstack test-setup-environments \
	check-seed-peers check-deploy-env
