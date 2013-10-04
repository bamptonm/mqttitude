all: apns-dev-cert-bundle.pem PyAPNS/dev-keyfile.pem PyAPNS/dev-cert.pem apns-prod-cert-bundle.pem PyAPNS/prod-keyfile.pem PyAPNS/prod-cert.pem

clean:
	rm -f apns-dev-cert-bundle.pem
	rm -f apns-prod-cert-bundle.pem
	rm -f PyAPNS/dev-keyfile.pem
	rm -f PyAPNS/dev-cert.pem
	rm -f PyAPNS/prod-keyfile.pem
	rm -f PyAPNS/prod-cert.pem
	rm -f apns-dev-cert.pem
	rm -f apns-dev-key.pem
	rm -f apns-dev-keynopwd.pem
	rm -f apns-prod-cert.pem
	rm -f apns-prod-key.pem
	rm -f apns-prod-keynopwd.pem

PyAPNS/prod-keyfile.pem:apns-prod-keynopwd.pem
	cp apns-prod-keynopwd.pem PyAPNS/prod-keyfile.pem

PyAPNS/prod-cert.pem:apns-prod-cert.pem
	cp apns-prod-cert.pem PyAPNS/prod-cert.pem

PyAPNS/dev-keyfile.pem:apns-dev-keynopwd.pem
	cp apns-dev-keynopwd.pem PyAPNS/dev-keyfile.pem

PyAPNS/dev-cert.pem:apns-dev-cert.pem
	cp apns-dev-cert.pem PyAPNS/dev-cert.pem

apns-dev-cert-bundle.pem:apns-dev-keynopwd.pem apns-dev-cert.pem
	cat apns-dev-cert.pem apns-dev-keynopwd.pem >apns-dev-cert-bundle.pem

apns-prod-cert-bundle.pem:apns-prod-keynopwd.pem apns-prod-cert.pem
	cat apns-prod-cert.pem apns-prod-keynopwd.pem >apns-prod-cert-bundle.pem

apns-dev-cert.pem:apns-dev-cert.p12
	openssl pkcs12 -clcerts -nokeys -out apns-dev-cert.pem -in apns-dev-cert.p12

apns-prod-cert.pem:apns-prod-cert.p12
	openssl pkcs12 -clcerts -nokeys -out apns-prod-cert.pem -in apns-prod-cert.p12

apns-dev-key.pem:apns-dev-key.p12
	openssl pkcs12 -out apns-dev-key.pem -in apns-dev-key.p12

apns-dev-keynopwd.pem:apns-dev-key.pem
	openssl rsa -out apns-dev-keynopwd.pem -in apns-dev-key.pem

apns-prod-key.pem:apns-prod-key.p12
	openssl pkcs12 -out apns-prod-key.pem -in apns-prod-key.p12

apns-prod-keynopwd.pem:apns-prod-key.pem
	openssl rsa -out apns-prod-keynopwd.pem -in apns-prod-key.pem

