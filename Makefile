.DEFAULT_GOAL := lint
DEPLOY_DOWNTIME ?= 0
BACKUP_SUFFIX ?= backup
BACKUP_DIR ?= /tmp/mnesia_backups

setup-terraform:
	cd terraform && terraform init && terraform apply --auto-approve

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

~/.ssh/id_ae_infra_ed25519:
	@ssh-keygen -t ed25519 -N "" -f $@

.PRECIOUS: ~/.ssh/id_ae_infra_ed25519-%-cert.pub
~/.ssh/id_ae_infra_ed25519-%-cert.pub: ~/.ssh/id_ae_infra_ed25519
	@vault write -field=signed_key ssh/sign/$* public_key=@$<.pub > $@

cert-%: ~/.ssh/id_ae_infra_ed25519-%-cert.pub
	@

cert: cert-epoch

ssh-%: cert-%
	@ssh $*@$(HOST)

ssh: ssh-epoch

# TODO also add ansible idempotent tests here
unit-tests:
	cd terraform && terraform init && terraform plan

integration-tests-run:
	cd test/terraform && terraform init
	cd test/terraform && terraform apply --auto-approve
	# TODO this is actually a smoke test that can be migrated to "goss"
	cd ansible && ansible-playbook health-check.yml --limit=tag_env_tf_test

integration-tests-cleanup:
	cd test/terraform && terraform destroy --auto-approve

integration-tests: integration-tests-run integration-tests-cleanup

lint:
	ansible-lint ansible/*.yml --exclude ~/.ansible/roles
	cd terraform && terraform init && terraform validate && terraform fmt -check=true -diff=true

# TODO move this to "goss" acceptance tests
# Keep in sync from https://github.com/aeternity/epoch/blob/master/config/sys.config
check-seed-peers:
	# UAT
	curl -fs -m 5 http://52.10.46.160:3013/v2/peers/pubkey | grep -q 'QU9CvhAQH56a2kA15tCnWPRJ2srMJW8ZmfbbFTAy7eG4o16Bf'
	curl -fs -m 5 http://18.195.109.60:3013/v2/peers/pubkey | grep -q '2vhFb3HtHd1S7ynbpbFnEdph1tnDXFSfu4NGtq46S2eM5HCdbC'
	curl -fs -m 5 http://13.250.162.250:3013/v2/peers/pubkey | grep -q '27xmgQ4N1E3QwHyoutLtZsHW5DSW4zneQJ3CxT5JbUejxtFuAu'
	curl -fs -m 5 http://18.130.148.7:3013/v2/peers/pubkey | grep -q 'nt5N7fwae3DW8Mqk4kxkGAnbykRDpEZq9dzzianiMMPo4fJV7'
	# Mainnet
	curl -fs -m 5 http://35.178.61.73:3013/v2/peers/pubkey | grep -q '5mmzrsoPh9owYMfKhZSkUihufDTB6TuayD173Ng464ukVm9xU'
	curl -fs -m 5 http://35.177.192.219:3013/v2/peers/pubkey | grep -q '2KWhoNRdythXAmgCbM6QxFo95WM4XXGq2pjcbKitXFpUHnPQc3'
	curl -fs -m 5 http://18.136.37.63:3013/v2/peers/pubkey | grep -q '2L8A5vSjnkLtfFNpJNgP9HbmGLD7ZAGFxoof47N8L4yyLAyyMi'
	curl -fs -m 5 http://52.220.198.72:3013/v2/peers/pubkey | grep -q '2gPZjuPnJnTVEbrB9Qgv7f4MdhM4Jh6PD22mB2iBA1g7FRvHTk'
	curl -fs -m 5 http://52.56.252.75:3013/v2/peers/pubkey | grep -q 'frAKABjDnM3QZCUygbkaFvbd8yhv6xdufazDFLgJRc4fnGy3s'
	curl -fs -m 5 http://3.16.242.93:3013/v2/peers/pubkey | grep -q 'tVdaaX4bX54rkaVEwqE81hCgv6dRGPPwEVsiZk41GXG1A4gBN'
	curl -fs -m 5 http://3.17.30.101:3013/v2/peers/pubkey | grep -q '2mwr9ikcyUDUWTeTQqdu8WJeQs845nYPPqjafjcGcRWUx4p85P'
	curl -fs -m 5 http://52.56.66.124:3013/v2/peers/pubkey | grep -q 'FLpSUrKwgBAu5uVRnB2iWKtwGAHZckxvtCbjVPeeCA3j33t3J'
	curl -fs -m 5 http://13.58.177.66:3013/v2/peers/pubkey | grep -q '2CAJwwmM2ZVBHYFB6na1M17roQNuRi98k6WPFcoBMfUXvsezVU'
	curl -fs -m 5 http://13.250.190.66:3013/v2/peers/pubkey | grep -q 'vxK2ikV9djG8MXmDnYYs338ETEsaUPweZrc2S54L3scxBfncU'
	curl -fs -m 5 http://34.218.57.207:3013/v2/peers/pubkey | grep -q '28si4QQ4YkjpZdo5cER7nxQodT2cMv7uNLBzUmaTkfU7EVHFH9'
	curl -fs -m 5 http://34.209.38.2:3013/v2/peers/pubkey | grep -q 'iLdkHHPrQByhAEkAf9SoBZwH5gsbBv6UKB72nC82P5od7PMXc'
	curl -fs -m 5 http://18.217.69.24:3013/v2/peers/pubkey | grep -q 'H4ooofyixJE6weqsgzKMKTdjZwEWb2BMSWqdFqbwZjssvtUEZ'
	curl -fs -m 5 http://3.0.217.255:3013/v2/peers/pubkey | grep -q '2qPAV7cYcHBK8MDo7neB2p1ow5Bmu1o56EUtnVv19ytuZ3pTtX'
	curl -fs -m 5 http://3.8.105.183:3013/v2/peers/pubkey | grep -q '2mWh671xYJRdzXFmJGy4M1Vhsy8y4ECadmoAcTYMw6pEGW5VCz'
	curl -fs -m 5 http://3.8.30.66:3013/v2/peers/pubkey | grep -q 'rwTYPQY8cvFebULRnpYZ3pVqK9xhnUW41SpRWr51R1bzp4x5'
	curl -fs -m 5 http://3.17.15.122:3013/v2/peers/pubkey | grep -q '2eu9njAqnd2s9nfSHNCHMbw96dajSATz1rgT6PokH2Lsa531Sp'
	curl -fs -m 5 http://3.17.30.125:3013/v2/peers/pubkey | grep -q 'SFA9D5wc9uZ2amhL7nmXSmcv4qBthKKC64RdFy5ZWGZAbSkDt'
	curl -fs -m 5 http://35.166.231.86:3013/v2/peers/pubkey | grep -q '21DNLkjdBuoN7EajkK3ePfRMHbyMkhcuW5rJYBQsXNPDtu3v9n'
	curl -fs -m 5 http://52.11.110.179:3013/v2/peers/pubkey | grep -q 'RKVZjm7UKPLGvyKWqVZN1pXN6CTCxfmYz2HkNL2xiAhLVd2ho'
	curl -fs -m 5 http://54.214.159.45:3013/v2/peers/pubkey | grep -q 'AnPnGst52qzh7ii8KUzHHFwFGiXxyF2TALhds9LPguAxJJqKd'
	curl -fs -m 5 http://52.88.74.110:3013/v2/peers/pubkey | grep -q '2u68ui39npbsjDVAy7Q1vBYFxfgaV3AWbXL8UB38TuKsgehHF1'
	curl -fs -m 5 http://35.177.165.232:3013/v2/peers/pubkey | grep -q 'BPYCajukjRmJkPQ3nY4TyjPZ969aCMDqWZkZ3EDXkxJbvN2cH'
	curl -fs -m 5 http://3.0.221.40:3013/v2/peers/pubkey | grep -q '26SjCczbcdG49nC8wWh3ZUZna6eyF9rbpFymSc6wKyCiten1LQ'
	curl -fs -m 5 http://35.177.212.38:3013/v2/peers/pubkey | grep -q '2GBVGpHdZzmxA5k92RiY39RpjVNgECQRNfeFQ6z7ruJ5PPn5hH'
	curl -fs -m 5 http://18.218.172.119:3013/v2/peers/pubkey | grep -q 'Xv6KMd1612pLWznW37s2fx79QMHGbLZuXTyFvuXRrHSNb8s5o'
	curl -fs -m 5 http://52.40.117.141:3013/v2/peers/pubkey | grep -q 'XpZVMtsbg39Rm69aBP3m2Q245ght8MNUGN1omBr7xJmd4goxR'
	curl -fs -m 5 http://34.211.251.83:3013/v2/peers/pubkey | grep -q '21fv4vH2GbmL35gb6tWhwFQjMnprftuGQ4Xx97VehSM8eQdB7U'
	curl -fs -m 5 http://13.250.144.60:3013/v2/peers/pubkey | grep -q 'sGegC48UrvDA7cvvUU3GPTze9wNUnnK1P4q46mL5jAFddNrbD'
	curl -fs -m 5 http://35.176.217.240:3013/v2/peers/pubkey | grep -q 'io8yyDuTfCUmLkLShXvvkZEJFnfC6oVMnrS2tUygLkbbnnJxd'
	curl -fs -m 5 http://18.130.106.60:3013/v2/peers/pubkey | grep -q '4cHNMu9xgXE1DvDrqdaUypr1yzmwhHSUrTyT8o9u8954bYCau'
	curl -fs -m 5 http://35.163.118.175:3013/v2/peers/pubkey | grep -q 'cVrCJWsg2vyWnRerEpLyB6ut6A8AA1MchQWAheRFNWpRWHXHJ'
	curl -fs -m 5 http://3.0.12.164:3013/v2/peers/pubkey | grep -q '2dWtS7LECJwjkRXQKoDP3mspdVJ4TPhwBfkiWMPSPMNYyT7jzn'
	curl -fs -m 5 http://18.216.167.138:3013/v2/peers/pubkey | grep -q '2aAEHdDFNbqH23HdZqu6HMtQmaE6rvLQuDZqEEWndkNbWunyuY'
	curl -fs -m 5 http://3.17.15.239:3013/v2/peers/pubkey | grep -q '2R7a7JHzfZQU5Ta7DJnFiqRr7ayCcAVakqYzJ2mvZj5k4ms5mV'
	curl -fs -m 5 http://3.0.86.27:3013/v2/peers/pubkey | grep -q '2Vi6BTNLoFyyYCmAFWxcfRAmHKfb7gWPj8p73uqb9MtW3dXEbG'
	curl -fs -m 5 http://52.26.157.37:3013/v2/peers/pubkey | grep -q '8nn6ypcwkaXxJfPGq7DCpBpf9FNfmkXPvGCjJFnLzvwjhCMEH'
	curl -fs -m 5 http://3.17.17.128:3013/v2/peers/pubkey | grep -q 'zUqmdQBnJjBKjrcVgJgEJU36mjJnUT7z59p8UVp5f6vA9Taxa'
	curl -fs -m 5 http://13.228.202.140:3013/v2/peers/pubkey | grep -q 'QkNjQbJL3Ab1TVG5GesKuZTixBdXEutUtxG677mVu9D4mMNRr'
	curl -fs -m 5 http://52.77.168.79:3013/v2/peers/pubkey | grep -q '2jtDgarjfr7S5NBZpBBx3fgn3wdtLb24UmiYGtVCGzF6x7Bytb'

check-deploy-env:
ifndef DEPLOY_ENV
	$(error DEPLOY_ENV is undefined)
endif

ansible/inventory-list.json:
	cd ansible && ansible-inventory --list > inventory-list.json

list-inventory: ansible/inventory-list.json
	cd ansible &&\
	cat inventory-list.json | ./dump_inventory.py

clean:
	rm ~/.ssh/id_ae_infra*
	rm -f ansible/inventory-list.json

.PHONY: \
	images setup-terraform setup-node setup-monitoring setup \
	manage-node reset-net lint cert-% ssh-% ssh clean \
	check-seed-peers check-deploy-env list-inventory
