# Setting up TLS on the [Mosquitto] broker



The basic configuration for TLS in [mosquitto.conf][mconf] is:

```
listener 8883
tls_version tlsv1
cafile .............
certfile .............
keyfile .............
```

(see also: [mosquitto-tls][mtls].)

* `8883` is the standard MQTT port for TLS connections. Change it if you need to, but make sure your MQTTitude app uses the same port.
* `tls_version` specifies TLSv1 which is currently a requirement for the MQTTitude apps, as their APIs support that TLS version.
* `cafile` is the path to the certificate authority file
* `certfile` points to your server's certificate in PEM format
* `keyfile` points to your server's secret key file (which you *never* divulge!)

The following sections are not an endorsement of a particular Certification Authority, but rather are a few tips on getting you set up with [Mosquitto].

### startssl.com

If you have a key-pair issued by _startssl.com_, you'll be issued a key (in a `*.key` file), and a certificate (as `*.pem` or `*.crt` -- either contains a PEM-encoded certificate).

[Mosquitto] will need the certificate chain for _startssl.com_, which you can find as [ca-bundle.crt](http://www.startssl.com/certs/ca-bundle.crt) at [www.startssl.com/certs/](http://www.startssl.com/certs/).

As far as TLS is concerned, you'll therefore set up your `mosquitto.conf` as follows, specifying corrrect paths to the files.

```
listener 8883
tls_version tlsv1
cafile ca-bundle.crt
certfile server.crt
keyfile server.key
```

Then download the _startssl.com_ CA certificate ([ca.crt](http://www.startssl.com/certs/ca.crt)) and [install that](TLS-certificates.md) on your device.


  [mosquitto]: http://mosquitto.org
  [mconf]: http://mosquitto.org/man/mosquitto-conf-5.html
  [mtls]: http://mosquitto.org/man/mosquitto-tls-7.html
