var map;	// Gobal
var redIcon;	// Global
var latlngs = Array();

function load_map()
{
	map = L.map('map').setView([51.505, -0.09], 13);
	var linecolor = 'green';
	var latlngs = Array();
		
	//Extend the Default marker class
	// http://harrywood.co.uk/maps/examples/leaflet/custom-marker.view.html
	var RedIcon = L.Icon.Default.extend({
            options: {
            	    iconUrl: 'assets/marker-icon-red.png' 
            }
         });
	redIcon = new RedIcon();
         
	// FIXME: where do I start? Which tile?!?

	L.tileLayer('http://{s}.tile.cloudmade.com/BC9A493B41014CAABB98F0471D759707/997/256/{z}/{x}/{y}.png', {
		maxZoom: 18,
		attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery ?? <a href="http://cloudmade.com">CloudMade</a>'
	}).addTo(map);

}

// topic is received topic
// d is parsed JSON payload
// date is Date() object
function mapit(topic, d, date)
{
	if (topic == config.mytopic) {
		me = L.marker([d.lat, d.lon], {icon: redIcon}).addTo(map);
		text = topic + "<br/>" + me.getLatLng().lat + ", " + me.getLatLng().lng;
		me.bindPopup(text);
		latlngs.push(me.getLatLng());
	} else { // a friend
		user = getUser(topic);
		if (!user.name) {
			// doesn't exist. Create something
			users[topic] = {
				name: topic,
				icon: leaf_icon(gravatar('foo@example.com'))
			};
		}

		if (user.marker) {
			f = friend_move(d.lat, d.lon, topic);
		} else {
			f = friend_add(d.lat, d.lon, topic);
		}
		latlngs.push(f.getLatLng());
	}

	/* Add lat/lon to array and make sure map encapsulates every
	 * point */

	map.fitBounds(L.latLngBounds(latlngs));
}
