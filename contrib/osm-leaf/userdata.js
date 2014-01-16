
var users = {};


function gravatar(email) {
	var md5 = hex_md5(email.trim().toLowerCase());
	var url = 'http://www.gravatar.com/avatar/' + md5;
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
		var u = users[topic];
		u.icon = leaf_icon(gravatar(u.mail));
		// alert(topic + ": " + u.name + " " + u.mail);
	}

}

function getUser(topic)
{
	return users[topic] = users[topic] || {};
}

function getPopupText(user, lat, lon) {
	var text = user.name + "<br/>" + lat + ", " + lon;
	return text;
}

function friend_add(user, lat, lon)
{
	// Add marker with icon (and text) and return marker object
	// TODO: text could have reverse-geo on it ...

	var m = L.marker([lat, lon], {
		icon: user.icon
		}).addTo(map);

	
	m.bindPopup(getPopupText(user, lat, lon));

	/* Bind a mouseover to the marker */
	m.on('mouseover', function(evt) {
		evt.target.openPopup();
	});


	// Bind marker to user
	user.marker = m;

	return user.marker;
}

function friend_move(user, lat, lon)
{
	if (user.marker) {
		user.marker.setLatLng({lat: lat, lng: lon});
		user.marker.setPopupContent(getPopupText(user, lat, lon));
	}

	return user.marker;
}
