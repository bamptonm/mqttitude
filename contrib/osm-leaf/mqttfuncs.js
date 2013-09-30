function mqtt_connect()
{
	var client = new Messaging.Client(config.websockethost, config.websocketport,
				"leaf" + parseInt(Math.random() * 100, 10));

	client.onConnectionLost = function (responseObject) {
		$('#mqttstatus').val("connection lost: " + responseObject.errorMessage);
	};

	client.onMessageArrived = function (message) {
		topic = message.destinationName;

		try {
			payload = message.payloadString;
			var d = $.parseJSON(payload);
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
		onSuccess: function () {
			$('#mqttstatus').val("connected");
			client.subscribe(config.friendstopic, {qos: 0});
			client.subscribe(config.mytopic, {qos: 0});
		},
		onFailure: function (message) {
			$('#mqttstatus').val("Connection failed: " + message.errorMessage);
		}
	};

	/* Connect to MQTT broker */
	client.connect(options);
}

