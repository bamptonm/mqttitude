# Specifications for MQTTitude

This documents the specifications layed out for MQTTitude.

## Apps

Two apps, one for iOS and another for Android devices (minimal OS versions as yet unknown) will periodically collect device location information, in particular _latitude_, _longitude_ and a _timestamp_ which will be published on a best-effort basis to a user-specified MQTT broker.

### Common app features

#### Settings

* broker address (hostname, IP)
* broker port (TCP port)
* TLS (yes/no)
* Autentication (username, password)
* MQTT topic on which to publish
* QoS
* Retain (under discussion: maybe not required)

#### Data

Apps will publish a JSON payload as described in [JSON-pub](json-pub.md)


## Backend

The MQTTitude "back-end" is a set of utilities and services which consume the data published by the MQTTitude apps. These basically consist of

* an MQTT broker
* a database
* a Web interface

### MQTT broker

Any compatible MQTT broker can be used, as long as it supports the features offerred by the apps, in particular _TLS_ and _authentication_.

### Database

* MySQL (maybe prefer PostgreSQL b/c of licensing?)

### MQTTitude Web interface

* Display user location over time as list of places/countries
* If possible, display routes on "map", e.g. using [Leaflet](http://leafletjs.com)
