all: apns-dev-cert-bundle.pem PyAPNS/keyfile.pem PyAPNS/cert.pem

clean:
	rm -f apns-dev-cert-bundle.pem
	rm -f PyAPNS/keyfile.pem
	rm -f PyAPNS/cert.pem
	rm -f apns-dev-cert.pem
	rm -f apns-dev-key.pem
	rm -f apns-dev-keynopwd.pem

PyAPNS/keyfile.pem:apns-dev-keynopwd.pem
	cp apns-dev-keynopwd.pem PyAPNS/keyfile.pem

PyAPNS/cert.pem:apns-dev-cert.pem
	cp apns-dev-cert.pem PyAPNS/cert.pem

apns-dev-cert-bundle.pem:apns-dev-keynopwd.pem apns-dev-cert.pem
	cat apns-dev-cert.pem apns-dev-keynopwd.pem >apns-dev-cert-bundle.pem

apns-dev-cert.pem:apns-dev-cert.p12
	openssl pkcs12 -clcerts -nokeys -out apns-dev-cert.pem -in apns-dev-cert.p12

apns-dev-key.pem:apns-dev-key.p12
	openssl pkcs12 -out apns-dev-key.pem -in apns-dev-key.p12

apns-dev-keynopwd.pem:apns-dev-key.pem
	openssl rsa -out apns-dev-keynopwd.pem -in apns-dev-key.pem

