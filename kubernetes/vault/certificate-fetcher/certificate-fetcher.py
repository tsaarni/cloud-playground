#!/usr/bin/env python3

import hvac
import os
import os.path


client    = hvac.Client(url=os.environ['VAULT_ADDR'], token=os.environ['VAULT_TOKEN'])
hostname  = os.environ['CERT_SAN_DNSNAME']
directory = os.environ['CERT_PATH']


print('requesting certificate from vault for host=%s' % hostname)
res = client.write('pki/issue/pods', common_name=hostname)


print('writing files to %s' % directory)
open(os.path.join(directory, 'cert.pem'),     'w').write(res['data']['certificate'])
open(os.path.join(directory, 'key.pem'),      'w').write(res['data']['private_key'])
open(os.path.join(directory, 'ca-cert.pem'),  'w').write(res['data']['issuing_ca'])
