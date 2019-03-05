.DEFAULT_GOAL := lint
DEPLOY_DOWNTIME ?= 0
BACKUP_SUFFIX ?= backup
BACKUP_DIR ?= /tmp/mnesia_backups
TF_LOCK_TIMEOUT=5m
VAULT_TOKENS_TTL ?= 4h
SEED_CHECK_ENVS = main uat unstable

check-terraform-changes:
	cd terraform/environments && terraform init -lock-timeout=$(TF_LOCK_TIMEOUT)
	cd terraform/environments && terraform plan -lock-timeout=$(TF_LOCK_TIMEOUT) -detailed-exitcode

setup-terraform:
	cd terraform/environments && terraform init -lock-timeout=$(TF_LOCK_TIMEOUT)
	cd terraform/environments && terraform apply -lock-timeout=$(TF_LOCK_TIMEOUT) --auto-approve

setup-node: check-deploy-env
	cd ansible && ansible-playbook \
		--limit="tag_env_$(DEPLOY_ENV):&tag_role_aenode" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e vault_addr=$(VAULT_ADDR) \
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

mnesia_backup:
	cd ansible && ansible-playbook \
		--limit="tag_role_aenode:&tag_env_$(BACKUP_ENV)" \
		-e ansible_python_interpreter=/usr/bin/python3 \
		-e download_dir=$(BACKUP_DIR) \
		-e backup_suffix=$(BACKUP_SUFFIX) \
		mnesia_backup.yml

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
	cd ansible && ansible-playbook health-check.yml --limit=tag_env_$(TF_VAR_env_name)

integration-tests-cleanup:
	cd test/terraform && terraform destroy --auto-approve

integration-tests: integration-tests-run integration-tests-cleanup

lint:
	ansible-lint ansible/*.yml --exclude ~/.ansible/roles
	cd terraform/environments && terraform init && terraform validate && terraform fmt -check=true -diff=true

# TODO move this to "goss" acceptance tests
# Keep in sync from https://github.com/aeternity/aeternity/blob/master/config/sys.config
# Keep it by region and sorted!
check-seed-peers:
	# UAT
	curl -fs -m 5 http://13.250.162.250:3013/v2/peers/pubkey | grep -q '27xmgQ4N1E3QwHyoutLtZsHW5DSW4zneQJ3CxT5JbUejxtFuAu'
	curl -fs -m 5 http://13.53.161.215:3013/v2/peers/pubkey |grep -q 'DMLqy7Zuhoxe2FzpydyQTgwCJ52wouzxtHWsPGo51XDcxc5c8'
	curl -fs -m 5 http://18.195.109.60:3013/v2/peers/pubkey | grep -q '2vhFb3HtHd1S7ynbpbFnEdph1tnDXFSfu4NGtq46S2eM5HCdbC'
	curl -fs -m 5 http://52.10.46.160:3013/v2/peers/pubkey | grep -q 'QU9CvhAQH56a2kA15tCnWPRJ2srMJW8ZmfbbFTAy7eG4o16Bf'
	# Mainnet: ap-southeast-1
	curl -fs -m 5 http://13.228.202.140:3013/v2/peers/pubkey | grep -q 'QkNjQbJL3Ab1TVG5GesKuZTixBdXEutUtxG677mVu9D4mMNRr'
	curl -fs -m 5 http://13.250.144.60:3013/v2/peers/pubkey | grep -q 'sGegC48UrvDA7cvvUU3GPTze9wNUnnK1P4q46mL5jAFddNrbD'
	curl -fs -m 5 http://13.250.190.66:3013/v2/peers/pubkey | grep -q 'vxK2ikV9djG8MXmDnYYs338ETEsaUPweZrc2S54L3scxBfncU'
	curl -fs -m 5 http://18.136.37.63:3013/v2/peers/pubkey | grep -q '2L8A5vSjnkLtfFNpJNgP9HbmGLD7ZAGFxoof47N8L4yyLAyyMi'
	curl -fs -m 5 http://3.0.12.164:3013/v2/peers/pubkey | grep -q '2dWtS7LECJwjkRXQKoDP3mspdVJ4TPhwBfkiWMPSPMNYyT7jzn'
	curl -fs -m 5 http://3.0.217.255:3013/v2/peers/pubkey | grep -q '2qPAV7cYcHBK8MDo7neB2p1ow5Bmu1o56EUtnVv19ytuZ3pTtX'
	curl -fs -m 5 http://3.0.221.40:3013/v2/peers/pubkey | grep -q '26SjCczbcdG49nC8wWh3ZUZna6eyF9rbpFymSc6wKyCiten1LQ'
	curl -fs -m 5 http://3.0.86.27:3013/v2/peers/pubkey | grep -q '2Vi6BTNLoFyyYCmAFWxcfRAmHKfb7gWPj8p73uqb9MtW3dXEbG'
	curl -fs -m 5 http://52.220.198.72:3013/v2/peers/pubkey | grep -q '2gPZjuPnJnTVEbrB9Qgv7f4MdhM4Jh6PD22mB2iBA1g7FRvHTk'
	curl -fs -m 5 http://52.77.168.79:3013/v2/peers/pubkey | grep -q '2jtDgarjfr7S5NBZpBBx3fgn3wdtLb24UmiYGtVCGzF6x7Bytb'
	# Mainnet: us-west-2
	curl -fs -m 5 http://34.209.38.2:3013/v2/peers/pubkey | grep -q 'iLdkHHPrQByhAEkAf9SoBZwH5gsbBv6UKB72nC82P5od7PMXc'
	curl -fs -m 5 http://34.211.251.83:3013/v2/peers/pubkey | grep -q '21fv4vH2GbmL35gb6tWhwFQjMnprftuGQ4Xx97VehSM8eQdB7U'
	curl -fs -m 5 http://34.218.57.207:3013/v2/peers/pubkey | grep -q '28si4QQ4YkjpZdo5cER7nxQodT2cMv7uNLBzUmaTkfU7EVHFH9'
	curl -fs -m 5 http://35.163.118.175:3013/v2/peers/pubkey | grep -q 'cVrCJWsg2vyWnRerEpLyB6ut6A8AA1MchQWAheRFNWpRWHXHJ'
	curl -fs -m 5 http://35.166.231.86:3013/v2/peers/pubkey | grep -q '21DNLkjdBuoN7EajkK3ePfRMHbyMkhcuW5rJYBQsXNPDtu3v9n'
	curl -fs -m 5 http://52.11.110.179:3013/v2/peers/pubkey | grep -q 'RKVZjm7UKPLGvyKWqVZN1pXN6CTCxfmYz2HkNL2xiAhLVd2ho'
	curl -fs -m 5 http://52.26.157.37:3013/v2/peers/pubkey | grep -q '8nn6ypcwkaXxJfPGq7DCpBpf9FNfmkXPvGCjJFnLzvwjhCMEH'
	curl -fs -m 5 http://52.40.117.141:3013/v2/peers/pubkey | grep -q 'XpZVMtsbg39Rm69aBP3m2Q245ght8MNUGN1omBr7xJmd4goxR'
	curl -fs -m 5 http://52.88.74.110:3013/v2/peers/pubkey | grep -q '2u68ui39npbsjDVAy7Q1vBYFxfgaV3AWbXL8UB38TuKsgehHF1'
	curl -fs -m 5 http://54.214.159.45:3013/v2/peers/pubkey | grep -q 'AnPnGst52qzh7ii8KUzHHFwFGiXxyF2TALhds9LPguAxJJqKd'
	# Mainnet: us-east-2
	curl -fs -m 5 http://13.58.177.66:3013/v2/peers/pubkey | grep -q '2CAJwwmM2ZVBHYFB6na1M17roQNuRi98k6WPFcoBMfUXvsezVU'
	curl -fs -m 5 http://18.216.167.138:3013/v2/peers/pubkey | grep -q '2aAEHdDFNbqH23HdZqu6HMtQmaE6rvLQuDZqEEWndkNbWunyuY'
	curl -fs -m 5 http://18.217.69.24:3013/v2/peers/pubkey | grep -q 'H4ooofyixJE6weqsgzKMKTdjZwEWb2BMSWqdFqbwZjssvtUEZ'
	curl -fs -m 5 http://18.218.172.119:3013/v2/peers/pubkey | grep -q 'Xv6KMd1612pLWznW37s2fx79QMHGbLZuXTyFvuXRrHSNb8s5o'
	curl -fs -m 5 http://3.16.242.93:3013/v2/peers/pubkey | grep -q 'tVdaaX4bX54rkaVEwqE81hCgv6dRGPPwEVsiZk41GXG1A4gBN'
	curl -fs -m 5 http://3.17.15.122:3013/v2/peers/pubkey | grep -q '2eu9njAqnd2s9nfSHNCHMbw96dajSATz1rgT6PokH2Lsa531Sp'
	curl -fs -m 5 http://3.17.15.239:3013/v2/peers/pubkey | grep -q '2R7a7JHzfZQU5Ta7DJnFiqRr7ayCcAVakqYzJ2mvZj5k4ms5mV'
	curl -fs -m 5 http://3.17.17.128:3013/v2/peers/pubkey | grep -q 'zUqmdQBnJjBKjrcVgJgEJU36mjJnUT7z59p8UVp5f6vA9Taxa'
	curl -fs -m 5 http://3.17.30.101:3013/v2/peers/pubkey | grep -q '2mwr9ikcyUDUWTeTQqdu8WJeQs845nYPPqjafjcGcRWUx4p85P'
	curl -fs -m 5 http://3.17.30.125:3013/v2/peers/pubkey | grep -q 'SFA9D5wc9uZ2amhL7nmXSmcv4qBthKKC64RdFy5ZWGZAbSkDt'
	# Mainnet: eu-north-1
	curl -fs -m 5 http://13.53.114.199:3013/v2/peers/pubkey | grep -q '7N7dkCbg39MYzQv3vCrmjVNfy6QkoVmJe3VtiZ3HRncvTWAAX'
	curl -fs -m 5 http://13.53.149.181:3013/v2/peers/pubkey | grep -q '22FndjTkMMXZ5gunCTUyeMPbgoL53smqpM4m1Jz5fVuJmPXm24'
	curl -fs -m 5 http://13.53.161.210:3013/v2/peers/pubkey | grep -q '2HjB1wZrAubYUCH3jfosMaWV9ZVq6GP3PKAG8CVfQPxKwFcLsw'
	curl -fs -m 5 http://13.53.162.212:3013/v2/peers/pubkey | grep -q '2QPVSDntnXzVpcjhAiiWCsXbP5WyAof9erGP4Wr47F8dVY9Nwy'
	curl -fs -m 5 http://13.53.164.121:3013/v2/peers/pubkey | grep -q 'Xgsqi4hYAjXn9BmrU4DXWT7jURy2GoBPmrHfiCoDVd3UPQYcU'
	curl -fs -m 5 http://13.53.213.137:3013/v2/peers/pubkey | grep -q '2LnQXCmGqEJymtHAeUGjgcXU7dPLBbsut9rAXDG3nb7sCQK4fN'
	curl -fs -m 5 http://13.53.51.175:3013/v2/peers/pubkey | grep -q '22fVESEbuKNaQWNTWH45PLH7tazAKHev4PCdKBmuVgU1BC7mKu'
	curl -fs -m 5 http://13.53.77.98:3013/v2/peers/pubkey | grep -q 'vTDXS3HJrwJecqnPqX3iRxKG5RBRz9MdicWGy8p9hSdyhAY4S'
	curl -fs -m 5 http://13.53.78.163:3013/v2/peers/pubkey | grep -q 'NPrJPXfzBU8da5Ufy2o2LmyHXhLX733NPHER2Xh3cTcbK2BDD'
	curl -fs -m 5 http://13.53.89.32:3013/v2/peers/pubkey | grep -q '27VNp1gHQQsNa2hBPB7na6CUCtvobqAe7sQmPKBW4G3v6uEq9s'
	# Unstable
	curl -fs -m 5 http://3.8.38.115:3013/v2/peers/pubkey | grep -q '2N6MS9Sm5ULbh54iCDvVxFUZ7WcoDLCdJQEDNdfmf5MRSTDGV1'

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
	manage-node reset-net lint cert-% ssh-% ssh clean \
	check-seed-peers check-deploy-env list-inventory \
	check-seed-peers-% check-seed-peers-all \
	health-check-node health-check-% health-check-all
