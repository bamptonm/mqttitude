# How obtaining location is implemented

## Android

The way it currently works is by specifying an interval in which you want to receive updates (the one you configure in the settings). You only receive updates if this amount of time has passed *AND* you moved more than 500m (when the app is in the background. The movement restriction is set to 50m or so when in the foreground).

So, say I set an interval of 10min and I don't move; will I get a PUBlish?

Yes. If you move more than 1000 meters in 5 minutes you'll get a PUB after 10 minutes. You won't get a PUB after 5 minutes though.

## IOS 

IOS offers 3 modes of location publication
* MANUAL mode
* SIGNIFICANT LOCATION CHANGE mode
* MOVE mode
and the independent
* REGION monitoring (aka Geo Fences)

### MOVE mode 

In MOVE mode, the app monitors location permanently and publishes a new location as soon as the device
moves x meters or after y seconds, whatever happens first. x and y can be adjusted by the user
in the systems settings for MQTTitude. The defaults are 100m and 300 seconds (5 minutes). 

The payoff is higher battery usage as high as in navigation or tracker app.
So it is recommend to use MOVE mode while charging or during moves only - hence the name.

### SIGNIFICANT LOCATION CHANGE mode

IOS defines a SIGNIFICANT LOCATION CHANGE as travelling a distance of at least 500 meters in 5 minutes.
This mode allows the app to run in background and minimize the power consumption.

This standard tracking mode reports significant location changes only (>500m and at most once every 5 minutes).
This is defined by Apple and is optimal with respect to battery usage.

Examples:

* if you don't move, no new location is published - even if you don't move for hours
* if you move at least 500 meters, a new location will be published after 5 minutes
* if you move 10 kilometers in 5 minutes, only one location will be published


### MANUAL mode

The app doens't monitor location changes in MANUAL mode while in background. The user has to press the location
button to publish the current location.

### REGION monitoring

The app user may mark a previously manually published location as a region and specify a monitoring radius in meters.
The app will publish the location additionally everytime the device leaves or enters one of the regions.

Region monitoring is not related to one of the location publication modes and works independently. It is switched on when a region is setup with description and radius. To switch region monitoring off, all regions have to be deleted or unmarked (by setting radius to 0).

Regions are shown on the map display in transparent blue or red circles. Red indicates the device is is within the region.

~                                                                                                                                                                                        
~                                                                                                                                                                                        
~                                                                                                                                                                                        
~                                                                                                                                                                                        
~                                                                                                                                                                                        
~                           
