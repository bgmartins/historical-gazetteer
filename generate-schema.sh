#!/bin/sh

# Create the database
sqlite3 gazetteer.db <gazetteer-sql-schema.sql
spatialite gazetteer.db "update g_location_geometry set encoded_geometry = GeomFromText(encoded_geometry,4326)"
spatialite gazetteer.db "update g_location set bounding_box_geodetic = BuildMbr(west_coordinate,south_coordinate,east_coordinate,north_coordinate,4326)"
python3 import_periodo.py
python3 import_decm.py
#python3 import_tgn.py

# Download schema crawler
mkdir temp
cd temp
wget https://github.com/schemacrawler/SchemaCrawler/releases/download/v15.04.01/schemacrawler-15.04.01-distribution.zip
unzip schemacrawler-15.04.01-distribution.zip

# The path of the unzipped SchemaCrawler directory
SchemaCrawlerPATH=./schemacrawler-15.04.01-distribution

# The path of the SQLite database
SQLiteDatabaseFILE=../gazetteer.db

# The type of the database system.
RDBMS=sqlite

# Where to store the image
OutputPATH1=../auxiliary-files/database-diagram.pdf
OutputPATH2=../auxiliary-files/database-report.html

# Username and password need to be empty for SQLite
USER=
PASSWORD=
 
# Generate diagram
java -classpath $(echo ${SchemaCrawlerPATH}/_schemacrawler/lib/*.jar | tr ' ' ':') schemacrawler.Main -server=${RDBMS} -database=${SQLiteDatabaseFILE} -outputformat=pdf -outputfile=${OutputPATH1} -command=brief -routines= -tabletypes=TABLE -infolevel=standard -user=${USER} -password=${PASSWORD} -loglevel=OFF
java -classpath $(echo ${SchemaCrawlerPATH}/_schemacrawler/lib/*.jar | tr ' ' ':') schemacrawler.Main -server=${RDBMS} -database=${SQLiteDatabaseFILE} -outputformat=html -outputfile=${OutputPATH2} -command=details -routines= -tabletypes=TABLE -infolevel=maximum -user=${USER} -password=${PASSWORD} -loglevel=OFF
echo "Finished generating the diagram"

# Remove schema crawler
cd ..
rm -rf temp