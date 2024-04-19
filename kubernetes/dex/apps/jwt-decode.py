#!/bin/env python3
#
# Decodes JWT from stdin
#
# Install dependencies on ubuntu
#   apt-get install python3-jwt
#
# or with virtual env
#   python3 -m venv venv
#   . venv/bin/activate
#   pip install jwt￼
#
import jwt
import json
import time
import pprint
import os

tokendir = os.path.expanduser("~/.kube/cache/oidc-login/")

for file in os.listdir(tokendir):
    json_file = os.path.join(tokendir, file)
    with open(json_file, 'r') as f:
        print("# File: {}".format(json_file))
        json_data = json.load(f)
        t = jwt.decode(json_data["id_token"], verify=False, options={'verify_signature': False})
        pprint.pprint(t)

        if t.get('iat') is not None:
            print("# iat={}".format(time.ctime(t['iat'])))
        if t.get('exp') is not None:
            print("# exp={}".format(time.ctime(t['exp'])))
