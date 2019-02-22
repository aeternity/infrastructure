#!/usr/bin/env python

"""
Simple script that takes a ansible-inventory JSON output (stdin)
and dumps inventory markdown grouped by environment.

Examples
----------
ansible-inventory --list | ./dump_inventory.py

"""

import sys, json, re

env_group_prefix = 'tag_env_'

data = json.load(sys.stdin)
all_groups = data['all']['children']
filtered_groups = [g for g in all_groups]
env_groups = [g for g in filtered_groups if g.startswith(env_group_prefix)]

# source https://stackoverflow.com/a/16090640/3967231
def natural_sort_key(s, _nsre=re.compile('([0-9]+)')):
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split(_nsre, s)]

def print_host(host):
        host_ip = host
        if 'ansible_host' in hostvars[host]:
            host_ip = hostvars[host]['ansible_host']
        print("    - %s (%s) [status](http://%s:3013/v2/status) [top](http://%s:3013/v2/blocks/top)" % (host, host_ip, host_ip, host_ip))

def set_hosts_regions(hosts):
    regions = []
    for host in hosts:
        host_region = hostvars[host]['placement']['region']
        if host_region not in regions:
            regions.append(host_region)
    return regions

for group_name in env_groups:
    print("#### %s\n" % group_name[len(env_group_prefix):])
    hosts = data[group_name]['hosts'].sort(key=natural_sort_key)
    hostvars = data['_meta']['hostvars']
    seeds = []
    peers = []
    for host in data[group_name]['hosts']:
        if 'kind' in hostvars[host]['tags'] and hostvars[host]['tags']['kind'] == 'seed':
            seeds.append(host)
        else:
            peers.append(host)
    if seeds:
        print('**seeds:**')
        for region in set_hosts_regions(seeds):
            print("  *%s*:" % region )
            for seed in seeds:
                if hostvars[seed]['placement']['region'] == region:
                    print_host(seed)
    if peers:
        print('**peers:**')
        for region in set_hosts_regions(peers):
            print("  *%s*:" % region )
            for peer in peers:
                if hostvars[peer]['placement']['region'] == region:
                    print_host(peer)
    print("\n")
