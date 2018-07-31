#!/bin/bash

# Run this script from Ambari Server Node
# Configure PostgreSQL for "Hive Database", node6-sb
# 1. On PostgreSQL host, Install PostgreSQL connector:
yum install -y postgresql-jdbc*
# 2. Confirm .jar file is in Java share directory, Node6-sb
ls /usr/share/java/postgresql-jdbc.jar
ambari-server setup --jdbc-db=postgres --jdbc-driver=/usr/share/java/postgresql-jdbc.jar

# Install mysql on node1-sb for Hive
yum install -y mysql-connector-java
ls /usr/share/java/mysql-connector-java.jar
ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
