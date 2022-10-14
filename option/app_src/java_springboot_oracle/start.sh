#!/bin/bash
export DB_USER=##DB_USER##
export DB_PASSWORD=##DB_PASSWORD##
export SPRING_APPLICATION_JSON='{ "webquerydb.db.url": "##JDBC_URL##" }'
cd target
java -jar demo-0.0.1-SNAPSHOT.jar
