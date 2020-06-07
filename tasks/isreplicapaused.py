#!/usr/bin/python

import time
import psycopg2

SQL_PAUSE_REPLICATION="SELECT pg_is_wal_replay_paused();"

conn = psycopg2.connect(host="localhost", database="postgres", user="postgres")

cur = conn.cursor()

cur.execute(SQL_PAUSE_REPLICATION)

result={}
result['isreplicapaused']={}
result['isreplicapaused']['output']=str(cur.fetchone())

conn.close()

print(json.dumps(result))
