## Location object

This location object is published by the mobile apps and delivered by the backend JSON API.

```json
{
    "_type": "location",        // (a) (i)
    "lat"  : "xx.xxxxxx",       // (a) (i)
    "lon"  : "y.yyyyyy",        // (a) (i)
    "tst"  : "1376715317",      // (a) (i)
    "acc"  : "75",              // (a) (i)
    "batt" : "nn",              // (a) (i)
    "desc" : "xxxx",		// (a)
    "event" : "xxxx",		// (a)
}
```

* `lat` is latitude as decimal, represented as a string
* `lon` is longitude as decimal, represented as a string
* `tst` is a UNIX [epoch timestamp](http://en.wikipedia.org/wiki/Unix_time)
* `acc` is accuracy, in metres, with no unit. `[1]` (See: #211)
* `batt` is the device's battery level in percent (0 through 100) (iPhone: 5.3, Android 0.4)
* `desc` is the description of a waypoint (iOS app version >= 5.3)
* `event` is either `"enter"` or `"leave"` and tells if app is entering or leaving geofence (iOS version >= 5.3, see #209)

1. `acc` is a radius of uncertainty for the location, measured in metres.  The
    location’s _lat_ / _lon_ identify the center of the circle, and this value
    indicates the radius of that circle.

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

## Waypoint

Waypoints (currently in iOS app version >= 5.3) are published as Location objects
(i.e. with elements `tst`, `acc`, `lon`, `lat`, and `batt`)
and the following additional JSON attributes:

```json
{
    "_type" : "waypoint",
    "desc"  : "UTF-8 text entered on device",
    "rad"   : "<radius in metres specified by user>",
    ...
}
```

