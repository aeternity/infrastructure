#!/usr/bin/env python

"""
Simple script that takes a ansible-inventory JSON output (stdin)
and dumps seed nodes with public keys
You can specify environment with --env env_name or omit to get all hosts
"""
import sys, json, yaml, subprocess, re

inventory = json.load(sys.stdin)
all_envs = [ c for c in inventory['all']['children'] if c.startswith('tag_env_') ]

# source https://stackoverflow.com/a/16090640/3967231
def natural_sort_key(s, _nsre=re.compile('([0-9]+)')):
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split(_nsre, s)]

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
        print(err, file=sys.stderr)
        sys.exit(1)
    return out.decode("utf-8")

env_seed_list = []
inventory[env]['hosts'].sort(key=natural_sort_key)
for host in inventory[env]['hosts']:
    if host in inventory['tag_kind_seed']['hosts']:
        env_seed_list.append({'ip_addr': host, 'pubkey': get_peer_pubkey_from_vault(host)})
yaml.dump({'hosts': env_seed_list}, sys.stdout, default_flow_style=False)
