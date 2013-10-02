#!/usr/bin/env python

import ssl

# apns is from https://github.com/djacobs/PyAPNs
# just drop `apns.py' into the current directory
from apns import APNs, Payload

devicetoken = '3f34f3c7 9752986c 3128b935 a8f332bc b6ff71fa 54250bcf d2c1655f 29d71af5'
key_file = 'keyfile.pem'
cert_file = 'cert.pem'

payload = Payload(alert='Hello world!', sound='default', badge=1, custom={'whoami': 'JPmens'})
print payload.json()

hextoken = devicetoken.replace(' ', '')

apns = APNs(use_sandbox=False, cert_file=cert_file, key_file=key_file)

try:
    apns.gateway_server.send_notification(hextoken, payload)
except ssl.SSLError, e:
    print "SSL problem: ", str(e)
except:
    raise

for (token, fail_time) in apns.feedback_server.items():
    print token, fail_time
