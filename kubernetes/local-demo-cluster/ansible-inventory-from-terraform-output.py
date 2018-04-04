#!/usr/bin/env python3
#
# This script creates dynamic inventory file for Ansible from Terraform script output.
#
# Here is example output from "terraform output -json"
#
#   {
#       "addresses": {
#           "sensitive": false,
#           "type": "list",
#           "value": [
#               [
#                   "10.200.0.244"
#               ],
#               [
#                   "10.200.0.36"
#               ],
#               [
#                   "10.200.0.42"
#               ]
#           ]
#       },
#       "hostnames": {
#           "sensitive": false,
#           "type": "list",
#           "value": [
#               "kubernetes-1",
#               "kubernetes-2",
#               "kubernetes-3"
#           ]
#       }
#   }
#
#
# This is converted to following
#
#   {
#       "_meta": {
#           "hostvars": {
#               "kubernetes-1": {
#                   "ansible_host": "10.200.0.244"
#               },
#               "kubernetes-2": {
#                   "ansible_host": "10.200.0.36"
#               },
#               "kubernetes-3": {
#                   "ansible_host": "10.200.0.42"
#               }
#           }
#       },
#       "kubernetes": {
#           "hosts": [
#               "kubernetes-1",
#               "kubernetes-2",
#               "kubernetes-3"
#           ]
#       }
#   }
#
#
# The dynamic inventory syntax is described here
# http://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html
#

import subprocess
import json

s = subprocess.check_output("terraform output -json", shell=True)
j = json.loads(s)

combined = zip(j['addresses']['value'], j['hostnames']['value'])

inventory = { '_meta': {'hostvars': {}} }

for addresses, hostname  in combined:
    inventory['_meta']['hostvars'][hostname] = {'ansible_host': addresses[0]}

    groupname = hostname.rsplit('-', 1)[0]
    inventory.setdefault(groupname, {'hosts': []})['hosts'].append(hostname)


print(json.dumps(inventory, sort_keys=True, indent=4))
