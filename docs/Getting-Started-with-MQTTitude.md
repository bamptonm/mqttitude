# Getting started with MQTTitude

MQTTitude is an app which requires a so-called [MQTT] broker, and as such it isn't
quite plug-and-play. The app publishes your location information to a broker from
which you can further process that location data, for example, storing it in a 
database to track your movements. (For a bit of background on how this started,
look at [this post][3].)

## MQTT Brokers

An MQTT broker is a service to which MQTT clients connect. These clients publish
data to specific _topics_ and they can subscribe to one or more _topics_ to receive
messages. A _topic_ is like an "address" for a particular message. For example,
a topic for a device that publishes a temperature reading of your living room
may be `temperature/indoors/living`, whereas a device which publishes weather
data could do so to `weather/germany/frankfurt`. In the particular case of MQTTitude, we
use a topic branch called `mqttitude/username/device`, but you can override that
name if you prefer to. The reason we've chosen that structure is to accomodate
friends and family on a single broker, taking into consideration that a particular
user might have more than one device.

### Public broker

The easiest way to get started is probably by using one of the [public brokers][1], but
be **warned**: these brokers are _public_; in other words, everybody can (if they
guess the topic you're publishing on) read your current location.

Be that as it may, this can be useful to test MQTTitude before going to the 
trouble of setting up your own private broker.

We've had very good experience using `test.mosquitto.org` on port `1883`, and you
don't need to configure authentication in the app.

### Private broker

Ideally, you set up a private broker under your control. This sounds more difficult
than it actually is, and there are some very nice brokers you can use free of charge
on your own infrastructure. As an example, we've written up how to [install
Mosquitto on a Raspberry Pi][2].

## Testing

Once you've chosen an MQTT broker, make sure you feel comfortable with the
utilities it provides to subscribe and publish to topics. We recommend the
[Mosquitto] utilities for doing so.

For example, to subscribe to all topics prefixed by `mqttitude` on your broker:

```
mosquitto_sub -h hostname -p 1883 -v -t 'mqttitude/#'
```

(Note that the hash symbol has to be quoted in the shell which is why we've put
the whole topic branch in single quotes.)

In another screen you could publish a test message:

```
mosquitto_pub -h hostname -p 1883 -t 'mqttitude/test' -m 'hello world'
```

and in the first screen you'd see the topic name followed by a space and the message
_payload_.

Once you feel comfortable with what is going on, you can install and configure the app.

## MQTTitude app

Follow the instructions for [getting started with the iPhone app][4], and keep an eye
on your broker (with `mosquitto_sub`).


  [MQTT]: http://mqtt.org
  [1]: http://mqtt.org/wiki/doku.php/public_brokers
  [2]: http://jpmens.net/2013/09/01/installing-mosquitto-on-a-raspberry-pi/
  [3]: http://jpmens.net/2013/08/14/latitude-longitude-mqttitude/
  [mosquitto]: http://mosquitto.org
  [4]: https://github.com/binarybucks/mqttitude/blob/master/docs/Starting/iphone/Getting-Started.md
