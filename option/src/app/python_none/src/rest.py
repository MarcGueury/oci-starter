import os 
from app import app
from flask import jsonify
from flask import flash, request

@app.route('/dept')
def dept():
    return [ 
        { "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"},
        { "deptno": "10", "dname": "RESEARCH", "loc": "Cape Town"},
        { "deptno": "10", "dname": "SALES", "loc": "Brussels"},
        { "deptno": "10", "dname": "OPERATIONS", "loc": "San Francisco"}
    ]   

@app.route('/info')
def info():
        return "Python / Flask / No Database"          

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)