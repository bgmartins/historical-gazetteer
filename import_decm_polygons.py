import os
import re
import ftfy
import geopandas
import sqlite3
import pandas as pd

database = "gazetteer.db"
if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
conn = sqlite3.connect( database )
#conn.execute("INSERT INTO g_collection VALUES (1, 'DECM Data', '')")

def import_from_shapefile( shp_path , attribute_name , source_desc , feature_type , date_desc ): 
    data = geopandas.read_file(shp_path, encoding='utf8')
    for index, row in data.iterrows():
        name = ftfy.fix_text(str(row[attribute_name]).strip())
        geo = str(row["geometry"])
        bbox = row["geometry"].bounds
        
        if date_desc is None: date_desc = 'undefined-historical'
        time_pediod_id = conn.execute("SELECT g_time_period_to_period_name.time_period_id FROM l_time_period_name, g_time_period_to_period_name WHERE l_time_period_name.time_period_name_id=g_time_period_to_period_name.time_period_name_id AND time_period_name=?",(date_desc,)).fetchone()[0]
        language_id  = conn.execute("SELECT language_id FROM l_language WHERE language_code LIKE 'SPA'").fetchone()[0]

        feature_id  = conn.execute("SELECT MAX(feature_id) FROM g_feature").fetchone()        
        if feature_id is None: feature_id = 0
        else: feature_id = feature_id[0] + 1

        feature_name_id  = conn.execute("SELECT MAX(feature_name_id) FROM g_feature_name").fetchone() 
        if feature_name_id is None: feature_name_id = 0
        else: feature_name_id = feature_name_id[0] + 1

        location_id  = conn.execute("SELECT MAX(location_id) FROM g_location").fetchone()
        if location_id is None: location_id = 0
        else: location_id = location_id[0] + 1

        location_geometry_id = conn.execute("SELECT MAX(location_geometry_id) FROM g_location_geometry").fetchone() 
        if location_geometry_id is None or location_geometry_id[0] is None: location_geometry_id = 0
        else: location_geometry_id = location_geometry_id[0] + 1
                        
        conn.execute("INSERT INTO g_feature ( feature_id , collection_id , is_complete , time_period_id , entry_note , entry_date , modification_date ) VALUES (?,?,?,?,?,'now','now')", ( feature_id, 1, True, time_pediod_id, source_desc ) )
        conn.execute("INSERT INTO g_feature_name ( feature_name_id , feature_id , primary_display , language_id , transliteration_scheme_id , name ) VALUES (?,?,?,?,9,?)", ( feature_name_id, feature_id, True, language_id, name ) )
        conn.execute("INSERT INTO g_location ( location_id , feature_id , planet , bounding_box_geodetic , west_coordinate , east_coordinate , south_coordinate , north_coordinate , bounding_box_method , bounding_box_source_type ) VALUES (?,?,'Earth','EPSG:4019',?,?,?,?,'Bounding box computed from feature polygon', 'All' )", ( location_id, feature_id, bbox[0], bbox[2], bbox[1], bbox[3] ) )
        conn.execute("INSERT INTO g_location_geometry ( location_geometry_id, location_id, primary_geometry, local_geometry, geometry_coding_scheme_id, encoded_geometry, time_period_id ) VALUES (?,?,?,?,13,?,?)", (location_geometry_id, location_id, True, True, geo, time_pediod_id ) )
        conn.commit()

import_from_shapefile( "decm-data/decm-polygons/2_Gobiernos.shp" , "Gobierno", "Cline 1972", "administrative divisions", None )