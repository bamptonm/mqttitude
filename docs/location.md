# How obtaining location is implemented

## Android

The way it currently works is by specifying an interval in which you want to receive updates (the one you configure in the settings). You only receive updates if this amount of time has passed *AND* you moved more than 500m (when the app is in the background. The movement restriction is set to 50m or so when in the foreground).

So, say I set an interval of 10min and I don't move; will I get a PUBlish?

Yes. If you move more than 1000 meters in 5 minutes you'll get a PUB after 10 minutes. You won't get a PUB after 5 minutes though.

## IOS

IOS defines a "significant location change" as travelling a distance of at least 500 meters in 5 minutes. This mode allows the app
to run in background and minimize the power consumption.

Examples:

* if you don't move, no new location is published - even if you don't move for hours
* if you move at least 500 meters, a new location will be published after 5 minutes
* if you move 10 kilometers in 5 minutes, only one location will be published
