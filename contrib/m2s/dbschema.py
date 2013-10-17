#!/usr/bin/env python

from peewee import *
from config import Config
import datetime

cf = Config()

mysql_db = MySQLDatabase(cf.get('dbname', 'mqttitude'),
    user=cf.get('dbuser'),
    passwd=cf.get('dbpasswd'))

class MySQLModel(Model):

    class Meta:
        database = mysql_db

class Location(MySQLModel):
#    topic           = CharField(null=False)
    username        = CharField(null=False)
    device          = CharField(null=False)
    lat             = CharField(null=False)
    lon             = CharField(null=False)
    tst             = DateTimeField(default=datetime.datetime.now, index=True)
    acc             = CharField(null=True)
    weather         = CharField(null=True)
    celsius         = CharField(null=True)
    weather_data    = TextField(null=True)
    map_data        = TextField(null=True)


if __name__ == '__main__':
    mysql_db.connect()

    Location.create_table()

