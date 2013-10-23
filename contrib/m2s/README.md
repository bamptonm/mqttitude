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

### Data Plugins

Data plugins allow me to invoke a list of plugins in the order specified in settings. For example:

```python
data_plugins = [
        dict(column='weather',      filename='pl-weather.py'),
        dict(column='revgeo',       filename='pl-revgeo.py'),
]
```

The two plugins called `weather` and `revgeo` are loaded from their respective files. When `m2s` receives a message, it decodes the JSON into what we internally call an _item_. This _item_ is handed from plugin to plugin.

Each plugin returns a `(string, dict)` tuple. The string value is loaded into the database column named as the plugin (i.e. `weather` and `revgeo`) and must be pre-created in the database schema (see `dbschema.py`). The _dict_ is merged into the current _item_, whereby existing values _are not_ overwritten. The newly created _item_ is passed on to the next plugin if there is one.

Basically, a plugin looks like this:

```python
def plugin(item=None):

    lat = item['lat']
    lon = item['lon']

    # do something ...

    value = "*goes into column*"
    new_data = dict(a=1, b=2, c="something else")

    # the resulting JSON in the database will have this key added to it
    data = dict(my_special_data=new_data)

    return  (value, data)
```



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
