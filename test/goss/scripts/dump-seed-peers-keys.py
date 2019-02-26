#!/usr/bin/env python

"""
Simple script that takes a ansible-inventory JSON output (stdin)
and dumps seed nodes with public keys
You can specify environment with --env env_name or omit to get all hosts
"""
import sys, json, yaml, subprocess

inventory = json.load(sys.stdin)
all_envs = [ c for c in inventory['all']['children'] if c.startswith('tag_env_') ]

if len(sys.argv) > 2:
    param = sys.argv[2]
    if sys.argv[1] == '--env':
        env = 'tag_env_'+param
        if env not in all_envs:
            print("Environment \"%s\" does not exist in inventory" % param )
            sys.exit(1)
    else:
        print("You can specify environment with \"--env\"")
        sys.exit(1)
else:
    env = 'aws_ec2'

def get_peer_pubkey_from_vault(host):
    secret = "secret/aenode/peer_keys/%s/public" % host
    vault_cmd = ['vault', 'read', '-field', 'base58c', secret]
    vproc = subprocess.Popen(vault_cmd, stdout=subprocess.PIPE)
    out, err = vproc.communicate()
    if vproc.returncode > 0:
        print(err)
#        sys.exit(1)
    return out.decode("utf-8")

env_seed_list = []
for host in inventory[env]['hosts']:
    if host in inventory['tag_kind_seed']['hosts']:
        env_seed_list.append({'ip_addr': host, 'pubkey': get_peer_pubkey_from_vault(host)})
json.dump({'hosts': env_seed_list}, sys.stdout)
