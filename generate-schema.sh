#!/bin/sh

# Download schema crawler
mkdir temp
cd temp
wget https://github.com/schemacrawler/SchemaCrawler/releases/download/v14.20.06/schemacrawler-14.20.06-distribution.zip
unzip schemacrawler-14.20.06-distribution.zip

# The path of the unzipped SchemaCrawler directory
SchemaCrawlerPATH=./schemacrawler-14.20.06-distribution

# The path of the SQLite database
SQLiteDatabaseFILE=../gazetteer.db

# The type of the database system.
RDBMS=sqlite

# Where to store the image
OutputPATH=../ER-diagram.pdf

# Username and password need to be empty for SQLite
USER=
PASSWORD=
 
# Generate diagram
java -classpath $(echo ${SchemaCrawlerPATH}/_schemacrawler/lib/*.jar | tr ' ' ':') schemacrawler.Main -server=${RDBMS} -database=${SQLiteDatabaseFILE} -outputformat=pdf -outputfile=${OutputPATH} -command=brief -routines= -tabletypes=TABLE -infolevel=standard -user=${USER} -password=${PASSWORD} -loglevel=CONFIG
echo "Finished generating the diagram"

# Remove schema crawler
cd ..
rm -rf temp