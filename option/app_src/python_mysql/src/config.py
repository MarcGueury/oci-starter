import os 
from app import app
from flaskext.mysql import MySQL

mysql = MySQL()
db_url = os.getenv('DB_URL')
mysql_host = db_url.split(':')[0]
app.config['MYSQL_DATABASE_USER'] = os.getenv('DB_USER')
app.config['MYSQL_DATABASE_PASSWORD'] = os.getenv('DB_PASSWORD')
app.config['MYSQL_DATABASE_DB'] = 'db1'
app.config['MYSQL_DATABASE_HOST'] = mysql_host
mysql.init_app(app)