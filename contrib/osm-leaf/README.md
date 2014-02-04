

** NOTE: this has moved to [https://github.com/owntracks/contrib](https://github.com/owntracks/contrib)
Work in Progress!

![Screenshot](screenshot.jpg)

These things work:

* Load friends from users.json
* Obtain friends' icon from Gravatar
* move a friend when (s)he moves
* move self (red Icon)
* pan to bound all icons
* label popup with name, loc if name in users.json

## users.json

```json
{
    "mqttitude/jpm/3gs" : {
	    "name": "JP",
	    "mail": "jpmens@gmail.com"
    },
    "mqttitude/su00/nexus" : {
    	"name": "Suze Smith",
	"mail": "su@example.net"
    }
}
```

## TLS

Websockets over TLS has been tested using the `tls` branch of [WSS](https://github.com/stylpen/WSS/], which can do TLS on 'both' sides of a connection:

```


                       +------------------------------------+
                       |               WSS                  |
                       |------------------------------------|
                       |                                    |
                       |                                    |
                       |                                    |
         --ws-keyfile  |                                    |   --broker-ca
         --ws-chainfile|                                    |
       +--------------->                                    +--------------> MQTT broker
                       |                                    |
                       |                                    |
                       |                                    |
                       |                                    |
                       |                                    |
                       +------------------------------------+
```

As soon as you have a certificate and a key file for WSS proper, concatenate the two
into a single file which you pass to `ws-chainfile`. For example, using `generate-CA.sh`
you'd do as follows:

```
./generate-CA.sh
cat server.crt ca.crt > chain.pem
./WSS_static_armv6 \
	--brokerHost 192.168.1.130 \
	--brokerPort 8883 \
	--broker-tls-enabled \
	--ws-keyfile server.key \
	--ws-chainfile chain.pem \
	--verbose
```

## TODO

* add name, location, (reverse geo) to marker
* <del>can mouse-hover over marker show popup instead of having to click?</del> Done
* keep map positioned where it is w/o re-scale (easier see of moving markers)
* add activity counter right of map to show new friends' PUBs
* maybe show list of friends on right of map, with faces & location (like iOS app)?


## Credits

* [Leaflet.js](http://leafletjs.com).
* [jshash](http://pajhome.org.uk/crypt/md5/index.html) by Paul Johnston. (BSD)
* [jQuery](http://jquery.com/)

