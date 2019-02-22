import geopandas as gpd
import numpy as np
import pandas as pd
import sqlite3

shared_lib = '/usr/lib/x86_64-linux-gnu/libspatialite.so.7'
dbpath = 'gazetteer.db' 
con = sqlite3.connect(dbpath)
con.enable_load_extension(True)
con.execute("select load_extension('{0}');".format(shared_lib))

sql = "SELECT name, st, med_age, Hex(ST_AsBinary(GEOMETRY)) as geometry FROM cities;"
df = gpd.GeoDataFrame.from_postgis(sql, con, geom_col="geometry")
gdf = gpd.GeoDatFrame(df, geometry = df.geometry)
gdf.to_file(driver = 'ESRI Shapefile', filename= "result.shp")