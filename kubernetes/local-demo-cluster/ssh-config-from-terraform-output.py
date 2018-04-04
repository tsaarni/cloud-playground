#!/usr/bin/env python3
#
# This script creates ssh-config file for ssh from Terraform script output.
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
# This is converted to following:
#
#   Host kubernetes-1
#     HostName 10.200.0.244
#     User ubuntu
#
#   Host kubernetes-2
#     HostName 10.200.0.36
#     User ubuntu
#
#   Host kubernetes-3
#     HostName 10.200.0.42
#     User ubuntu
#
#
# The file can then be used e.g. by running `ssh -F ssh-config kubernetes-1`
#

import subprocess
import json

s = subprocess.check_output("terraform output -json", shell=True)
j = json.loads(s)

combined = zip(j['addresses']['value'], j['hostnames']['value'])

for addresses, hostname  in combined:
    print('Host {0}\n  HostName {1}\n  User ubuntu\n'.format(hostname, addresses[0]))
