## Location object

This location object is published by the mobile apps and delivered by the backend JSON API.

```json
{
    "_type": "location",	// (a) (i)
    "lat": "xx.xxxxxx", 	// (a) (i)
    "lon": "y.yyyyyy", 		// (a) (i)
    "tst": "1376715317",	// (a) (i)
    "acc": "75m",		// (a) (i)
}
```

* `lat` is latitude as decimal, represented as a string
* `lon` is longitude as decimal, represented as a string
* `tst` is a UNIX [epoch timestamp](http://en.wikipedia.org/wiki/Unix_time)
* `acc` is accuracy if available

## LWT

A _Last Will and Testament_ is optionally posted by the MQTT broker when it no longer has contact with the app. This typically looks like this:

```json
{
    "_type":"lwt",
    "tst":"1380738247"
}
```

The timestamp is the Unix epoch time at which the app first connected (i.e. *not* the time at which the LWT was published).
