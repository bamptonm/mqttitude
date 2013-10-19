## Getting started with the MQTTitude iPhone app

After downloading and installing the iPhone app, resist the temptation to launch it. Instead, go to your device's _Settings_, and locate _MQTTitude_. Click on that.

![](images/02.jpg)

You're now in the settings panel for MQTTitude, and there are three (4) things you have to change.

![](images/03.jpg)

1. _DeviceID_ is a short name you'll give your device. Good examples could be `iphone`, `myphone`, or `xyzz90`.
2. _Host_ is the host name or IP address of your MQTT broker. (The port defaults to 8883 because we default to using TLS.)
3. _UserID_ is your username on the broker. Even if your broker doesn't enforce authentication, you _must set a UserID_.
4. _Password_ is the password for _UserID_.

For example, I've set the following:

![](images/04.jpg)

Now launch MQTTitude.

![](images/09.jpg)

The first time you launch the app, you'll be asked to confirm that the app wants to use your location. You'll also be asked whether it should allow notifications, which you should answer with OK.

![](images/01.jpg)


You'll then see the app's main screen, and the connection to the MQTT broker is attempted.

![](images/08.jpg)

Verify the _Effective Settings_ by a click on _Status_. This shows you the URL the app is using, and importantly, the _DeviceID_ and _Topic_ it's using. By default the topic is constructed from the constant `mqttitude`, your _userid_, and  your _deviceid_.

![](images/05.jpg)

At this point in time you should check that the MQTT broker is actually receiving location messages. We recommend you subscribe to your broker as follows:

```
mosquitto_sub -h hostname -v -t '#'
```

Let's look at the main screen for a moment:

![](images/06.jpg)

The icons on the bottom row are as follows:

1. 
2. Type of map display.
3. The "Pin". Tapping this will deliver your current position to the MQTT broker immediately.
4. Mode: filled circle is automatic, empty cirle is manual, car is move-mode.
5. Status: green is connected, etc.

Tap on _Friends_ to see your position.

![](images/07.jpg)

The app's settings has a number of additional _Expert_ settings:

![](images/10.jpg)


![](images/11.jpg)

![](images/12.jpg)
