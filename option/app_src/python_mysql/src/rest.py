import pymysql
from app import app
from config import mysql
from flask import jsonify
from flask import flash, request

@app.route('/dept')
def dept():
    try:
        conn = mysql.connect()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SELECT deptno, dname, loc FROM dept")
        deptRows = cursor.fetchall()
        response = jsonify(deptRows)
        response.status_code = 200
        return response
    except Exception as e:
        print(e)
    finally:
        cursor.close() 
        conn.close()       
       
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)