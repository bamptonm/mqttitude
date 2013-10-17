#!/usr/bin/env python
# -*- coding: utf-8 -*-

# JPM

from config import Config
import mosquitto
import sys
import json
import datetime
import time
try:
    import json
except ImportError:
    import simplejson as json
import Queue
import threading
from weather import OpenWeatherMAP
from nominatim import ReverseGeo
from dbschema import Location

cf = Config()
owm = OpenWeatherMAP()
nominatim = ReverseGeo()
mqtt = mosquitto.Mosquitto()

q_in = Queue.Queue(maxsize=0)
num_workers = 1

def on_connect(mosq, userdata, rc):

    for topic in cf.get('topics'):
        print "Subscribing to ", topic
        mqtt.subscribe(topic, 0)

def on_disconnect(mosq, userdata, rc):
    print "OOOOPS! disconnect"

def on_publish(mosq, userdata, mid):
    print("--> PUB mid: "+str(mid))
    pass

def on_subscribe(mosq, userdata, mid, granted_qos):
    pass

def on_message(mosq, userdata, msg):
    print(msg.topic+" "+str(msg.qos)+" "+str(msg.payload))

    if msg.retain == 1:
        print "Skipping retained %s" % msg.topic
        return

    if 'isim' in msg.topic:
        return

    topic = msg.topic
    payload = str(msg.payload)
    payload = payload.replace('\0', '')

    try:
        data = json.loads(payload)
    except:
        print "Cannot decode JSON on topic %s" % (topic)
        return

    _type = data.get("_type", 'unknown')

    if _type != 'location':
        print "Skipping _type=%s" % _type
        return

    lat = data.get('lat')
    lon = data.get('lon')
    tst = data.get('tst', int(time.time()))

    if lat is None or lon is None:
        print "Skipping topic %s: lat or lon are None" % (topic)
        return

    # Split topic up into bits. Standard formula is "mqttitude/username/device"
    # so we do that here: modify to taste

    try:
        parts = topic.split('/')
        username = parts[1]
        deviceid = parts[2]
    except:
        deviceid = 'unknown'
        username = 'unknown'

    item = {
        'topic'         : topic,
        'device'        : deviceid,
        'username'      : username,
        'lat'           : lat,
        'lon'           : lon,
        'tst'           : tst,
        'acc'           : data.get('acc', None),
        'date_string'   :  time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(int(tst))),
    }

    # Shove it into the queue
    q_in.put(item)

def processor():
    '''
    Do the actual work on a decoded item.
    '''

    while True:
        item = q_in.get()

        print item
        topic = item.get('topic')
        lat = item.get('lat')
        lon = item.get('lon')

        print "WORKER: %s" % (topic)

        weather = {}
        address = {}
        if lat is not None and lon is not None:
            try:
                weather =  owm.weather(lat, lon)
                address = nominatim.reverse(lat, lon)
            except:
                pass

            item['weather_data'] = json.dumps(weather)
            item['map_data'] = json.dumps(address)
            item['weather'] = weather.get('current')    # "Rain"
            item['celsius'] = weather.get('celsius')    # 13.2
            item['tst'] = item['date_string']           # replace for database


            try:
                loca = Location(**item)
                loca.save()
            except:
                print "Cannot store in DB"

        else:
            print "WORKER: can't work: lat or lon missing!"

        q_in.task_done()


def main():
    mqtt.on_connect = on_connect
    mqtt.on_disconnect = on_disconnect
    mqtt.on_subscribe = on_subscribe
    # mqtt.on_publish = on_publish
    mqtt.on_message = on_message
    # mqtt.on_log = on_log

    username = cf.get('mqtt_username')
    password = cf.get('mqtt_password')

    if username is not None and password is not None:
        mqtt.username_pw_set(username, password)

    host = cf.get('mqtt_broker', 'localhost')
    port = int(cf.get('mqtt_port', '1883'))
    mqtt.connect(host, port, 60)

    # Launch worker threads to operate on queue
    for i in range(num_workers):
         t = threading.Thread(target=processor)
         t.daemon = True
         t.start()


    try:
        mqtt.loop_forever()
    except KeyboardInterrupt:
        print "Interrupted; waiting for background tasks"
        q_in.join()       # block until all tasks are done
        sys.exit(0)


if __name__ == '__main__':
    main()
