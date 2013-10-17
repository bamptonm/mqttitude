
import logging
from dbschema import Location

def storage(topic, item):
    """
    Storage plugin for m2s. The function signature MUST match the
    above. `topic' contains the message topic (e.g. "mqttitude/jpm/nexus")
    and `item' is a dict which contains the rest of the data (including
    weather and reverse geo-coding information if requested)

    This function need not return anything.
    """

    logging.debug("---- in storage: %s" % topic)

    try:
        loca = Location(**item)
        loca.save()
    except Exception, e:
        logging.info("Cannot store in DB: %s" % (str(e)))
