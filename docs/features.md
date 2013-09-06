# Features


This is **preliminary** documentation and **subject to change dramatically!**

## General

* Location information is PUBlished as a JSON string. [See json-pub](json-pub.md).

# Currently implemented

## Android

* The broker connection works well with:

  * No TLS (i.e. plain)
  * TLS using the Android build in certificate authorities (either the shipped
ones, or user provided ones that require a lock screen password to be set)
  * TLS with user-provided certificates via an absolute path (e.g. to Downloads).
    This doesn't require a password to be set on the device, but is a bit fiddly
    to set up.
  * Username/password auth works.

* Automatic publishes at configurable intervals (disabled or > 1 minute)

* Display of a marker at which the app believes the user to be at
  (lastKnownLocation)

* Reverse geo coding that displays the address of lastKnownLocation

* Accuracy of lastKnownLocation (if the accuracy is > 250m, the marker
  changes to a circle centered around lastKnownLocation with radius == accuracy)

* Button to manually publish  lastKnownLocation

* Button to share a Google Maps link that places a marker at lastKnownLocation

* For location the Google Fused Location Provider at Balanced Battery
  Settings is used. This one can re use GPS or other Position fixes that are
  requested by other apps in order to save battery and select the most
  appropriate position source.


## iOS

* Runs on iPhones running IOS >=6.1 (3GS, 4, 4S, 5) and iPads running IOS >=6.1 as an iPhone app. Not tested on iPods yet.

* Monitors "significant location changes" as define by Apple Inc (about 5 minutes AND 
  "significant location changes" (>500m))

* publishes this locations via MQTT to the configured server while in foreground and background.

* The current location can be send on request.

### Configuration

Configuration is done via the system settings app.

* MQTT server is configured by 
	* specifying hostname/ip-address,
	* port,
	* whether TLS is used and/or 
	* authentication is done via user/password

* If TLS is used, the server certificate needs to be distributed separately and installed on the IOS device

* Data is published on the server under a user-configurable `topic` with
	* QoS and
	* Retain

* App listens to one subscription topic and receives publications with the specified QoS lebel

### Map Display

* Displays a map with the current location and marks the last ~50 locations with timestamp and topic

* Shows a button to center the map on the current location and follow the current user location

* Shows a button to zoom out until all marked locations of user and friends are displayed.
* Shows a button to exit the app. If not exited, the app continues in the background.

* Connection indicator light shows current status of the MQTT server connection
  The server connection is established automatically when a new location shall be published.
  When the applicationo is moved to background, the connection is disconnected.
	* BLUE=IDLE, no connection established
	* GREEN=CONNECTED, server connection established
	* AMBER=ERROR OCCURED, WAITING FOR RECONNECT, app will automatically try to reconnect to the server
	* RED=ERROR, no connection to the server possible or transient errror condition

### Background Mode

The Application supports background-mode
* "significant location changes" are automatically published to the MQTT server
* If connected the listens to 
	* commands published by the server on topic <my topic>/listento. commands defined are
		* `publish`: app publishes current location immediately to the server
		* ...
	* published locations of other devices and displays the last location published per device on it's map
* app shows an application badge indicating the number of other device's loctions on it's map
* app shows notifications (in notification center) when publishing the user's location
* 
