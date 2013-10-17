#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__    = 'Jan-Piet Mens <jpmens()gmail.com>'
__copyright__ = 'Copyright 2013 Jan-Piet Mens'
__license__   = """Eclipse Public License - v 1.0 (http://www.eclipse.org/legal/epl-v10.html)"""

from config import Config
import mosquitto
import socket
import signal
import logging
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
import imp
import os

cf = Config()
owm = OpenWeatherMAP()
nominatim = ReverseGeo()
mqtt = mosquitto.Mosquitto()

q_in = Queue.Queue(maxsize=0)
num_workers = 1

LOGFILE = cf.get('logfile', 'logfile')
LOGFORMAT = '%(asctime)-15s %(message)s'
DEBUG=True

if DEBUG:
    logging.basicConfig(filename=LOGFILE, level=logging.DEBUG, format=LOGFORMAT)
else:
    logging.basicConfig(filename=LOGFILE, level=logging.INFO, format=LOGFORMAT)

logging.info("Starting")
logging.debug("DEBUG MODE")



def cleanup(signum, frame):
    """
    Signal handler to disconnect and cleanup.
    """

    logging.info("Disconnecting from broker")
    mqtt.disconnect()
    logging.info("Waiting for queue to drain")
    q_in.join()       # block until all tasks are done
    logging.info("Exiting on signal %d", signum)
    sys.exit(signum)

def on_connect(mosq, userdata, rc):
    """
    Subscribe to topics upon connecting
    """

    for topic in cf.get('topics'):
        logging.info("Subscribing to %s", topic)
        mqtt.subscribe(topic, 0)

def on_disconnect(mosq, userdata, rc):
    logging.info("OOOOPS! disconnect")

def on_publish(mosq, userdata, mid):
    logging.debug("--> PUB mid: %s" % (str(mid)))

def on_subscribe(mosq, userdata, mid, granted_qos):
    pass

def on_message(mosq, userdata, msg):
    """
    We get a message from the broker. If it's retained or it's topic
    contains a blocked word, skip it. Decode the JSON payload, check
    for correct _type (i.e. 'location'), ensure we have 'lat' and
    'lon' and shove it into the queue for the background thread to
    process.
    """

    if msg.retain == 1:
        logging.debug("Skipping retained %s" % msg.topic)
        return

    blocked_topics = cf.get('blocked_topics')
    if blocked_topics is not None:
        for t in blocked_topics:
            if t in msg.topic:
                logging.debug("Skipping blocked topic %s" % msg.topic)
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
    """
    Do the actual work on a decoded item. Get an item from the queue,
    if weather or reverse geo-coding are desired, do that, and save
    the result into persistent storage.
    """

    while True:
        item = q_in.get()

        topic = item.get('topic')
        lat = item.get('lat')
        lon = item.get('lon')

        logging.debug("WORKER is handling %s" % (topic))
        logging.debug(item)

        weather = {}
        address = {}
        if lat is not None and lon is not None:
            try:
                if cf.get('feature_weather'):
                    weather =  owm.weather(lat, lon)
                if cf.get('feature_revgeo'):
                    address = nominatim.reverse(lat, lon)
            except:
                pass

            if cf.get('feature_weather'):
                item['weather_data'] = json.dumps(weather)
                item['weather'] = weather.get('current')    # "Rain"
                item['celsius'] = weather.get('celsius')    # 13.2

            if cf.get('feature_revgeo'):
                item['map_data'] = json.dumps(address)


            item['tst'] = item['date_string']           # replace for database

            # If a storage plugin has been configured, use it if it's loadable.
            # If none has been configured or the plugin cannot be loaded, ignore

            storage_plugin = cf.get('storage_plugin')
            if storage_plugin is not None:
                do_store = True
                try:
                    mod = imp.load_source('storage', storage_plugin)
                except Exception, e:
                    logging.info("Can't import storage_plugin %s: %s" % (storage_plugin, e))
                    do_store = False

                if do_store:
                    try:
                        mod.storage(topic, item)
                    except Exception, e:
                        logging.info("storage_plugin %s: %s" % (storage_plugin, e))
        else:
            logging.info("WORKER: can't work: lat or lon missing!")

        q_in.task_done()


def main():
    """
    Connect to broker, launch daemon thread(s) and listen forever.
    """

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

    # Delays will be: 3, 6, 12, 24, 30, 30, ...
    mqtt.reconnect_delay_set(delay=3, delay_max=30, exponential_backoff=True)

    host = cf.get('mqtt_broker', 'localhost')
    port = int(cf.get('mqtt_port', '1883'))

    try:
        mqtt.connect(host, port, 60)
    except Exception, e:
        logging.info("MQTT connection failed: %s" % (str(e)))
        sys.exit(1)

    # Launch worker threads to operate on queue
    for i in range(num_workers):
         t = threading.Thread(target=processor)
         t.daemon = True
         t.start()


    while True:
        try:
            mqtt.loop_forever()
        except socket.error:
            logging.info("MQTT server disconnected; sleeping")
            time.sleep(5)
        except:
            raise


if __name__ == '__main__':
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    main()
