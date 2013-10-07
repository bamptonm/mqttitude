#!/usr/bin/env python

import ssl

# apns is from https://github.com/djacobs/PyAPNs
# just drop `apns.py' into the current directory
from apns import APNs, Payload

devicetoken = '9d9ed2f7 60780c69 1a4727e6 d428cbe7 7fd84bad 9ab16206 5afd8f4c f12feab3'
#
# development environment
#
#sandbox = True
#key_file = 'dev-keyfile.pem'
#cert_file = 'dev-cert.pem'

#
# production environment
#
sandbox = False
key_file = 'prod-keyfile.pem'
cert_file = 'prod-cert.pem'

payload = Payload(alert='Hello world!', sound='default', badge=1, custom={'whoami': 'JPmens'})
print payload.json()

hextoken = devicetoken.replace(' ', '')

apns = APNs(use_sandbox=sandbox, cert_file=cert_file, key_file=key_file)

try:
    apns.gateway_server.send_notification(hextoken, payload)
except ssl.SSLError, e:
    print "SSL problem: ", str(e)
except:
    raise

for (token, fail_time) in apns.feedback_server.items():
    print token, fail_time
