# MQTTitude to Storage (m2s)

This is part of the MQTTitude back-end. This program subscribes to a configured MQTT topic (default: `mqttitude/+/+`), extracts the JSON payload from received messages, optionally looks up weather and reverse-geo and others via plugins for the reported `lat` and `lon`, and stores the result. Storage is pluggable (see below), and we provide a default MySQL storage plugin.


```

                    +-------------------------+
                    |         m2s             |
                    |-------------------------|
                    |                         |
         +--------->| +---------+             |
                    |           |             |
                    |           |             |
                    |     +-----v-------+     |       +----------------+
                    |     |             +------------>| OpenWeatherMap |
                    |     |             |     |       +----------------+
                    |     |   Queue     |     |       
                    |     |             +------------>+----------------+
                    |     +-----+-------+     |       | Nominatim (Geo)|
                    |           |             |       +----------------+
                    |           |             |
                    |     +-----v-------+     |
                    |     | storage.py  |     |
                    |     |-------------|     |
                    |     |    SQL      |     |
                    |     |   NoSQL     |     |
                    |     |   Files     |     |
                    |     +-------------+     |
                    |                         |
                    +-------------------------+
```

### Configuration

1. Copy `settings.py.sample` to `settings.py` and edit. Note that this must be valid Python code
2. Pay particular attention to the _data_plugins_, which you can write yourself. 

### Plugins


### Storage

Storage of data is pluggable, and the default (in `storage.py`) uses peewee and MySQL. See `storage.py` and `settings.py` on how to change that.

### Create database

1. Create MySQL database
2. Check database settings in `settings.py`
3. run `python dbschema.py` to create the necessary tables

### Launch

```
./m2s.py
```


### Show

```
mysql> SELECT * FROM location;


### Weather

Weather data is obtained from [OpenWeatherMap.org](http://openweathermap.org/), but you can use your own source. Please observe [their terms](http://openweathermap.org/price)!

Temperatures are in Kelvin: subtract 273.15 to convert to Celsius.

```
curl 'http://api.openweathermap.org/data/2.5/weather?lat=48.858334&lon=2.295134'
```

```json
{
    "base": "gdps stations", 
    "clouds": {
        "all": 0
    }, 
    "cod": 200, 
    "coord": {
        "lat": 48.86, 
        "lon": 2.3
    }, 
    "dt": 1381939626, 
    "id": 6545270, 
    "main": {
        "humidity": 96, 
        "pressure": 1011, 
        "temp": 288.04, 
        "temp_max": 289.26, 
        "temp_min": 286.48
    }, 
    "name": "Palais-Royal", 
    "rain": {
        "1h": 1.02
    }, 
    "sys": {
        "country": "FR", 
        "sunrise": 1381904026, 
        "sunset": 1381942719
    }, 
    "weather": [
        {
            "description": "moderate rain", 
            "icon": "10d", 
            "id": 501, 
            "main": "Rain"
        }, 
        {
            "description": "light intensity drizzle rain", 
            "icon": "09d", 
            "id": 310, 
            "main": "Drizzle"
        }
    ], 
    "wind": {
        "deg": 280.5, 
        "speed": 4.96
    }
}
```

### Requirements

* Mosquitto (Python)
* [PeeWee](http://peewee.readthedocs.org/en/latest/). No need to install if you don't want to: put `peewee.py` alongside these files.
