#!/usr/bin/python

import time
import psycopg2

SQL_PAUSE_REPLICATION="SELECT pg_wal_replay_resume();"

conn = psycopg2.connect(host="localhost", database="postgres", user="postgres")

cur = conn.cursor()

cur.execute(SQL_PAUSE_REPLICATION)

result={}
result['resumereplica']={}
result['resumereplica']['output']=str(cur.fetchone())

conn.close()

print(json.dumps(result))
