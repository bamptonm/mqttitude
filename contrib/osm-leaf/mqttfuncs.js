function mqtt_connect()
{
	var client = new Messaging.Client(config.websockethost, config.websocketport,
				"leaf" + parseInt(Math.random() * 100, 10));

	client.onConnectionLost = function (responseObject) {
		$('#mqttstatus').html("Connection lost");
		$('#mqttstatus-details').html(responseObject.errorMessage);
	};

	client.onMessageArrived = function (message) {
		topic = message.destinationName;

		try {
			payload = message.payloadString;
			var d = $.parseJSON(payload);

			if (d._type != 'location') {
				return;
			}
			var date = new Date(d.tst * 1000); //convert epoch time to readible local datetime
			$('#msg').val(topic + " " + payload);
			console.log(topic + " " + d.lat + ", " + d.lon);
		} catch (err) {
			$('#msg').val("JSON parse error " + err);
			return;
		}

		mapit(topic, d, date);

	};

	var options = {
		timeout: 10,
		useSSL: config.usetls,
		onSuccess: function () {
			$('#mqttstatus').html("Connected");
			$('#mqttstatus-details').html("Host: " + config.websockethost + ", Port:" +  config.websocketport);
			client.subscribe(config.friendstopic, {qos: 0});
			client.subscribe(config.mytopic, {qos: 0});
		},
		onFailure: function (message) {
			$('#mqttstatus').html("Connection failed");
			$('#mqttstatus-details').html(message.errorMessage);
		}
	};

	/* Connect to MQTT broker */
	client.connect(options);
}

