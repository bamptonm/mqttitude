#!/usr/bin/env python

import ssl

# apns is from https://github.com/djacobs/PyAPNs
# just drop `apns.py' into the current directory
from apns import APNs, Payload

devicetoken = '769df01c e391d91b 1fc6bbb7 c16b533f d8ae80f1 1f453628 bbcb57b0 1aa9c31f'
key_file = 'keyfile.pem'
cert_file = 'cert.pem'

payload = Payload(alert='Hello world!', sound='default', badge=1, custom={'whoami': 'JPmens'})
print payload.json()

hextoken = devicetoken.replace(' ', '')

# use_sandbox = True for Development environment
# use_sandbox = False for Production environment

apns = APNs(use_sandbox=True, cert_file=cert_file, key_file=key_file)

try:
    apns.gateway_server.send_notification(hextoken, payload)
except ssl.SSLError, e:
    print "SSL problem: ", str(e)
except:
    raise

for (token, fail_time) in apns.feedback_server.items():
    print token, fail_time
