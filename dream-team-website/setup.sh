#! /bin/bash
#Install Postgres CLI
sudo apt-get install postgresql-9.4

#pip install modules
pip install flask-login flask-migrate Flask-WTF flask-bootstrap

#Connect to db: psql -h [host] [dbname] [user]
psql -h my-postgres-db-instance.cdu2zcgn1k7y.ap-southeast-2.rds.amazonaws.com development db_user

#start postgres commands
CREATE USER dt_admin WITH PASSWORD 'Password1';
CREATE DATABASE dreamteam_db;
GRANT ALL PRIVILEGES ON DATABASE dreamteam_db TO dt_admin;

#set Flask environment variables
export FLASK_CONFIG=development
export FLASK_APP=run.py

#begin flask migration operaions
flask db init
flask db migrate
flask db upgrade

#review dreamteam database as dt_admin
psql -h my-postgres-db-instance.cdu2zcgn1k7y.ap-southeast-2.rds.amazonaws.com dreamteam_db dt_admin

#Use flask shell to add an admin user to the database
flask shell
from app.models import Employee
from app import db
admin = Employee(email="admin@admin.com",username="admin",password="admin2016",is_admin=True)
db.session.add(admin)
db.session.commit()