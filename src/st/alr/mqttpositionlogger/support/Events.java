package st.alr.mqttpositionlogger.support;

import st.alr.mqttpositionlogger.MqttService;

public class Events {
    public static class MqttConnectivityChanged {
		private MqttService.MQTT_CONNECTIVITY connectivity;

		public MqttConnectivityChanged(
				MqttService.MQTT_CONNECTIVITY connectivity) {
			this.connectivity = connectivity;
		}

		public MqttService.MQTT_CONNECTIVITY getConnectivity() {
			return connectivity;
		}
	}
}