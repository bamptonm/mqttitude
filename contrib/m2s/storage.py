
import logging
from dbschema import Location, mysql_db

def storage(topic, item):
    """
    Storage plugin for m2s. The function signature MUST match the
    above. `topic' contains the message topic (e.g. "mqttitude/jpm/nexus")
    and `item' is a dict which contains the rest of the data (including
    weather and reverse geo-coding information if requested)

    This function need not return anything.
    """

    logging.debug("---- in storage: %s" % topic)

    item['tst'] = item['date_string']           # replace for database

    # Attempt to connect if not already connected. Takes care of MySQL 2006
    try:
        mysql_db.connect()
    except Exception, e:
        logging.info("Cannot connect to database: %s" % (str(e)))

    # Handle _type location/waypoint specifically

    if '_type' in item:
        if item['_type'] == 'waypoint':
            # Upsert
            try:
                mysql_db.execute_sql("""
                  REPLACE INTO waypoint
                  (topic, username, device, lat, lon, tst, rad, waypoint)
                  VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                  """, (
                  item['topic'], item['username'], item['device'], item['lat'],
                  item['lon'], item['tst'], item['rad'], item['desc'],))
            except Exception, e:
                logging.info("Cannot upsert waypoint in DB: %s" % (str(e)))

        else:
            try:
                loca = Location(**item)
                loca.save()
            except Exception, e:
                logging.info("Cannot store location in DB: %s" % (str(e)))

