#!/usr/bin/env python

from peewee import *
from config import Config
import datetime

cf = Config()

mysql_db = MySQLDatabase(cf.get('dbname', 'mqttitude'),
    user=cf.get('dbuser'),
    passwd=cf.get('dbpasswd'),
    threadlocals=True)

class MySQLModel(Model):

    class Meta:
        database = mysql_db

class Location(MySQLModel):
    topic           = BlobField(null=False)
    username        = CharField(null=False)
    device          = CharField(null=False)
    lat             = CharField(null=False)
    lon             = CharField(null=False)
    tst             = DateTimeField(default=datetime.datetime.now, index=True)
    acc             = CharField(null=True)
    batt            = CharField(null=True)
    waypoint        = TextField(null=True)  # desc in JSON, but desc is reserved SQL word
    event           = CharField(null=True)
    # optional: full JSON of item including all data from plugins
    json            = TextField(null=True)
    # the following fields must be correlated to settings.py (plugin columns)
    weather         = CharField(null=True)
    revgeo          = CharField(null=True)

class Waypoint(MySQLModel):
    topic           = BlobField(null=False)
    username        = CharField(null=False)
    device          = CharField(null=False)
    lat             = CharField(null=False)
    lon             = CharField(null=False)
    tst             = DateTimeField(default=datetime.datetime.now)
    rad             = CharField(null=True)
    waypoint        = CharField(null=True)

    class Meta:
        indexes = (
            # Create a unique index on tst
            (('tst', ), True),
        )

if __name__ == '__main__':
    mysql_db.connect()

    try:
        Location.create_table()
    except Exception, e:
        print str(e)

    try:
        Waypoint.create_table()
    except Exception, e:
        print str(e)

