# MQTTitude to Storage

### Configuration

1. Copy `settings.py.sample` to `settings.py` and edit. Note that this must be valid Python code

### Create database

1. Create MySQL database
2. run `python dbschema.py` to create the necessary tables


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
