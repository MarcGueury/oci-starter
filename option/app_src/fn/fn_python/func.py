#
# oci-adb-client-runsql-python version 1.0.
#
# Copyright (c) 2020 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

import io
import json
import logging
import oracledb

from fdk import response

def handler(ctx, data: io.BytesIO = None):
    try:
        conn = oracledb.connect(
          user=os.getenv('DB_USER'),
          password=os.getenv('DB_PASSWORD'),
          dsn=os.getenv('DB_URL'))
        print("Successfully connected to Oracle Database")
        cursor = conn.cursor()
        a = []
        for row in cursor.execute('select deptno, dname, loc from dept'):
            a.append( {"deptno": row[0], "dname": row[1], "loc": row[2]} )
        print(a)
        response = jsonify(a)
        response.status_code = 200
        return response
    except Exception as e:
        logging.getLogger().info('error: ' + str(ex))
    finally:
        cursor.close() 
        conn.close()     