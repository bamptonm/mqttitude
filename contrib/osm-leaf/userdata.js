
var users = {};


function gravatar(email) {
	md5 = hex_md5(email.trim().toLowerCase());
	url = 'http://www.gravatar.com/avatar/' + md5;
	return url;
}

function leaf_icon(url) {
	var icon = L.Icon.Default.extend({
            options: {
	    	iconUrl: url,
		iconSize: [35, 35],
	    }
         });
	return new icon;
}

function getuserlist() {
	$.ajax({
		type: 'GET',
		dataType: "json",
		url: config.userlisturl,
		async: false,
		data: {},
		success: function(data) {
				users = data; 
			},
		error: function(xhr, status, error) {
			alert('getuserlist: ' + status + ", " + error);
			}
	});

	for (var topic in users) {
		u = users[topic];
		u.icon = leaf_icon(gravatar(u.mail));
		// alert(topic + ": " + u.name + " " + u.mail);
	}

}

function getUser(topic)
{
	return users[topic] = users[topic] || {};
}

function friend_add(lat, lon, topic)
{
	// Add marker with icon (and text) and return marker object
	// TODO: text could have reverse-geo on it ...

	user = getUser(topic);
	m = L.marker([lat, lon], {
		icon: user.icon
		}).addTo(map);

	text = user.name + "<br/>" + m.getLatLng().lat + ", " + m.getLatLng().lng;
	m.bindPopup(text);

	/* Bind a mouseover to the marker */
	m.on('mouseover', function(evt) {
		evt.target.openPopup();
	});


	// Bind marker to user
	user.marker = m;

	return user.marker;
}

function friend_move(lat, lon, topic)
{
	user = getUser(topic);
	if (user.marker) {
		user.marker.setLatLng({lat: lat, lng: lon});
		text = user.name + "<br/>" + user.marker.getLatLng().lat + ", " + user.marker.getLatLng().lng;
		user.marker.setPopupContent(text);
	}

	return user.marker;
}
