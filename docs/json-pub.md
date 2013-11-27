## Location object

This location object is published by the mobile apps and delivered by the backend JSON API.

```json
{
    "_type": "location",	// (a) (i)
    "lat": "xx.xxxxxx", 	// (a) (i)
    "lon": "y.yyyyyy", 		// (a) (i)
    "tst": "1376715317",	// (a) (i)
    "acc": "75m",		// (a) (i)
    "batt": "nn",		// 
}
```

* `lat` is latitude as decimal, represented as a string
* `lon` is longitude as decimal, represented as a string
* `tst` is a UNIX [epoch timestamp](http://en.wikipedia.org/wiki/Unix_time)
* `acc` is accuracy if available
* `batt` is the device's battery level in percent (0 through 100) (not yet available)

## LWT

A _Last Will and Testament_ is optionally posted by the MQTT broker when it no longer has contact with the app. This typically looks like this:

```json
{
    "_type":"lwt",
    "tst":"1380738247"
}
```

The timestamp is the Unix epoch time at which the app first connected (i.e. *not* the time at which the LWT was published).

## deviceToken

The iPhone app sends out a _deviceToken_ object at initial connection to the broker. This is a device-unique token which can be used to notify the app via the Apple notification system. Note that this is experimental only and currently cannot be used!

```json
{
    "_type": "deviceToken", 
    "dev": "<abcded29 3f745ea9 c5f431a1 19a1b25c 53c85415 5a0a87c1 409aa683 410c3c3b>", 
    "tst": "1383818459"
}
```
