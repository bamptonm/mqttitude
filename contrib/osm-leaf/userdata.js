
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
	var geoloc = getRevGeo(lat,lon);
	var text = "<b>" + user.name + "</b><br/>" + lat + ", " + lon + "</br>" + geoloc;
	return text;
}

function getRevGeo(lat, lon) {
	var url = "http://nominatim.openstreetmap.org/reverse?format=json&lat=" + lat + "&lon=" + lon + "&zoom=18&addressdetails=1";
	var output = {}

	$.ajax({
		type: 'GET',
		dataType: "json",
		url: url,
		async: false,
		data: {},
		success: function(data) {
				output = data;
			},
		error: function(xhr, status, error) {
			alert('getRevGeo: ' + status + ", " + error);
			}
	});
	
	var text = "";
	if (output["address"]) {
		if (output["address"]["road"]) {
			text += output["address"]["road"];
			if (output["address"]["house_number"]) {
				text += " " + output["address"]["house_number"];
			}
		}
		
		if (output["address"]["city"]) {
			text += ", " + output["address"]["city"];
		} else if (output["address"]["county"]) {
			text += ", " + output["address"]["county"];
		} else if (output["address"]["country"]) {
			text += ", " + output["address"]["county"];
		}
		return text
	}
	
	return output["display_name"];
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
