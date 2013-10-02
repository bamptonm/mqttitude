all: apns-dev-cert-bundle.pem

clean:
	rm -f apns-dev-cert-bundle.pem
	rm -f apns-dev-cert.pem
	rm -f apns-dev-key.pem

apns-dev-cert-bundle.pem:apns-dev-key.pem apns-dev-cert.pem
	cat apns-dev-cert.pem apns-dev-key.pem >apns-dev-cert-bundle.pem

apns-dev-cert.pem:apns-dev-cert.p12
	openssl pkcs12 -clcerts -nokeys -out apns-dev-cert.pem -in apns-dev-cert.p12

apns-dev-key.pem:apns-dev-key.p12
	openssl pkcs12 -nokeys -out apns-dev-key.pem -in apns-dev-key.p12

