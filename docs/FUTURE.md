# Future

Thoughts on possible future enhancements.

## Short term

* Stability
* Reliability [#38](https://github.com/binarybucks/mqttitude/issues/38) 
* Battery consumption [#68](https://github.com/binarybucks/mqttitude/issues/68)
* Ensure UI has `Credits` with URL to Web site [#41](https://github.com/binarybucks/mqttitude/issues/41)
* Disable all location services (unload app) [#74](https://github.com/binarybucks/mqttitude/issues/74)
* LWT [#55](https://github.com/binarybucks/mqttitude/issues/55)

## Mid-term

* ~~Add "traffic light" [#73](https://github.com/binarybucks/mqttitude/issues/73)~~
* Add live "info" pane to Apps [#47](https://github.com/binarybucks/mqttitude/issues/47)
* Remote-control [#71](https://github.com/binarybucks/mqttitude/issues/71)
* Annotations.
  * Click on pin
  * Enter text string `"Restaurante La Comida; wonderful gambas al ajillo"`
  * PUBlish with full `_location` and additional `"note" : "...."`
* 2013-11-22: @mrose has some interesting things to say about Messages on iOS [#199](https://github.com/binarybucks/mqttitude/issues/199). In particular, screen real-estate should be better organized.


## Long-term

* Add presence. Are my friends in the area?
  * Needs friends/family on same broker
  * Needs 'standardized' topic names (maybe with Twitter id in topic?)
* Queue updates on device (with `tst` etc) to be PUBlished upon available connection
* Corner-pegging [#94](https://github.com/binarybucks/mqttitude/issues/94)
* Maybe add remote-control for enabling "move-mode" on iOS (https://github.com/binarybucks/mqttitude/issues/139)

## Very-long term, a.k.a. "Neat ideas"

* Publish incoming phone call (caller-id), [submitted by @bordingnon](http://twitter.com/bordignon/status/372627079059079168). JPM: Also SMS? Have to force TLS then, at least.
* Requested in #86: "app should register a subscriprion (configurable topic) a) if someone sends a text message it should be displayed as popup window b) if someone sends an HTML message it should be opened in a embedded browser"

#### Waypoints

JPM added 2013-11-22: We currently have "Annotations" on iOS (see above). I'd like to be able to have an annotation PUBlished to the broker so that m2s (or other processors) can pick it up. I propose the following payload: `{ "_type": "_waypoint", "tst":"xx", "lat":"<current>", "lon":<current>", "text":"utf-8 text" }`

