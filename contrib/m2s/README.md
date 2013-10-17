# MQTTitude to Storage

### Configuration

1. Copy `settings.py.sample` to `settings.py` and edit. Note that this must be valid Python code
2. Pay particular attention to the _features_, namely whether you'd like weather data and reverse-geocoding data.

### Storage

Storage of data is pluggable, and the default (in `storage.py`) uses peewee and MySQL. See `storage.py` and `settings.py` on how to change that.

### Create database

1. Create MySQL database
2. run `python dbschema.py` to create the necessary tables

### Launch

```
./m2s.py
```


### Show

```
mysql> SELECT * FROM location;
*************************** 1. row ***************************
          id: 1
    username: jjolie
      device: ipod
         lat: 48.858334
         lon: 2.295134
         tst: 2013-10-17 06:30:36
         acc: 1414m
     weather: Mist
     celsius: 10.7
weather_data: {"current": "Mist", "celsius": "10.7", "blob": {"clouds": {"all": 80}, "name": "Courbevoie", "coord": {"lat": 48.86, "lon": 2.3}, "sys": {"country": "FR", "sunset": 1382029003, "sunrise": 1381990518}, "weather": [{"main": "Mist", "id": 701, "icon": "50d", "description": "mist"}], "rain": {"3h": 0}, "base": "gdps stations", "dt": 1381991356, "main": {"pressure": 1018, "humidity": 95, "temp_max": 284.82, "temp": 283.81, "temp_min": 283.15}, "id": 6455399, "wind": {"gust": 4.11, "speed": 4.11, "deg": 220}, "cod": 200}}
    map_data: {"display_name": "Tour Eiffel, Avenue Pierre Loti, Gros-Caillou, 7e Arrondissement, Paris, \u00cele-de-France, 75725, France m\u00e9tropolitaine, European Union", "place_id": "20399540", "lon": "2.29450008726263", "osm_type": "way", "licence": "Data \u00a9 OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright", "osm_id": "5013364", "lat": "48.8582609", "address": {"pedestrian": "Avenue Pierre Loti", "city": "Paris", "suburb": "Gros-Caillou", "country": "France m\u00e9tropolitaine", "county": "Paris", "attraction": "Tour Eiffel", "state": "\u00cele-de-France", "city_district": "7e Arrondissement", "postcode": "75725", "country_code": "fr", "continent": "European Union"}}
```

### Weather

Weather data is obtained from [OpenWeatherMap.org](http://openweathermap.org/). Please observe [their terms](http://openweathermap.org/price)!

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
