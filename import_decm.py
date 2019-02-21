import os
import re
import ftfy
import geopandas
import sqlite3
import pandas as pd

database = "gazetteer.db"
if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
conn = sqlite3.connect( database )
conn.enable_load_extension(True)
#conn.execute('SELECT load_extension("mod_spatialite")')

def get_identifier(table_name, column_name):
    res = conn.execute("SELECT CASE WHEN MAX(" + column_name + ") = COUNT(*) THEN MAX(" + column_name + ") + 1 WHEN MIN(" + column_name + ") > 1 THEN 1 WHEN MAX(" + column_name + ") <> COUNT(*) THEN (SELECT MIN(" + column_name + ")+1 FROM " + table_name + " WHERE (" + column_name + "+1) NOT IN (SELECT " + column_name + " FROM " + table_name + ")) ELSE 1 END FROM " + table_name)
    return res.fetchone()[0]

def import_polygons_from_shapefile( collection_id, shp_path , attribute_name , source_desc , source_mnemonic , feature_type , date_desc ): 
    source_id = get_identifier("g_source","source_id")
    source_reference_id = get_identifier("l_source_reference","source_reference_id")
    entry_source_id = get_identifier("g_entry_source","entry_source_id")  
    conn.execute("INSERT INTO l_source_reference ( source_reference_id, citation, reference_author_id ) VALUES (?,?,1)", (source_reference_id, source_desc) )
    conn.execute("INSERT INTO g_source ( source_id, source_mnemonic, contributor_id, source_reference_id ) VALUES (?,?,2,?)", (source_id, source_mnemonic, source_reference_id) )
    conn.execute("INSERT INTO g_entry_source ( entry_source_id, source_id, entry_date ) VALUES (?,?,'now')", (entry_source_id,source_id) )
    data = geopandas.read_file(shp_path, encoding='utf8')
    for index, row in data.iterrows():
        name = ftfy.fix_text(str(row[attribute_name]).strip())
        geo = str(row["geometry"])
        bbox = row["geometry"].bounds
        if date_desc is None: date_desc = 'undefined-historical'
        time_period_id = conn.execute("SELECT g_time_period_to_period_name.time_period_id FROM l_time_period_name, g_time_period_to_period_name WHERE l_time_period_name.time_period_name_id=g_time_period_to_period_name.time_period_name_id AND time_period_name=?",(date_desc,)).fetchone()[0]
        classification_term_id = conn.execute("SELECT scheme_term_id FROM l_scheme_term WHERE term=? ORDER BY term_order_number, term_rank_number",(feature_type,)).fetchone()[0]
        language_id  = conn.execute("SELECT language_id FROM l_language WHERE language_code LIKE 'SPA'").fetchone()[0]
        feature_id = get_identifier("g_feature","feature_id")
        feature_name_id = get_identifier("g_feature_name","feature_name_id")
        location_id = get_identifier("g_location","location_id")        
        location_geometry_id = get_identifier("g_location_geometry","location_geometry_id")
        classification_id = get_identifier("g_classification","classification_id")
        feature_code_id = get_identifier("g_feature_code","feature_code_id")
        conn.execute("INSERT INTO g_feature ( feature_id , collection_id , is_complete , time_period_id , entry_note , entry_date , modification_date ) VALUES (?,?,?,?,?,'now','now')", ( feature_id, collection_id, True, time_period_id, source_desc ) )
        conn.execute("INSERT INTO g_feature_name ( feature_name_id , feature_id , primary_display , language_id , transliteration_scheme_id , name ) VALUES (?,?,?,?,9,?)", ( feature_name_id, feature_id, True, language_id, name ) )
        conn.execute("INSERT INTO g_location ( location_id , feature_id , planet , bounding_box_geodetic , west_coordinate , east_coordinate , south_coordinate , north_coordinate , bounding_box_method , bounding_box_source_type ) VALUES (?,?,'Earth','EPSG:4019',?,?,?,?,'Bounding box computed from feature polygon', 'All' )", ( location_id, feature_id, bbox[0], bbox[2], bbox[1], bbox[3] ) )
        conn.execute("INSERT INTO g_location_geometry ( location_geometry_id, location_id, primary_geometry, local_geometry, geometry_coding_scheme_id, encoded_geometry, time_period_id ) VALUES (?,?,?,?,13,?,?)", (location_geometry_id, location_id, True, True, geo, time_period_id ) )
        conn.execute("INSERT INTO g_classification ( classification_id, feature_id, classification_term_id, primary_display, time_period_id ) VALUES (?,?,?,?,?)", (classification_id, feature_id, classification_term_id, True, time_period_id))
        conn.execute("INSERT INTO g_feature_code ( feature_code_id, feature_id, code, code_scheme_id ) VALUES (?,?,?,?)", (feature_code_id,feature_id,feature_type,12) )
        conn.execute("INSERT INTO s_feature ( feature_id, time_period_id, entry_source_id ) VALUES (?,?,?)", (feature_id, time_period_id, entry_source_id) )
        conn.execute("INSERT INTO s_feature_code ( feature_code_id , entry_source_id ) VALUES (?,?)", (feature_code_id,entry_source_id) )
        conn.execute("INSERT INTO s_location ( location_id , bounding_box_source_entry_id ) VALUES (?,?)", (location_id,entry_source_id) )
        conn.execute("INSERT INTO s_location_geometry ( location_geometry_id, time_period_id, entry_source_id ) VALUES (?,?,?)", (location_geometry_id,time_period_id,entry_source_id) )
        conn.execute("INSERT INTO s_feature_name ( feature_name_id, name, language_id, transliteration_scheme_id, confidence_note ) VALUES (?,?,?,9,?)", (feature_name_id,entry_source_id,language_id,entry_source_id) )
        conn.commit()

collection_id = get_identifier("g_collection", "collection_id")
conn.execute("INSERT INTO g_collection VALUES (?, 'DECM Data', '')", (collection_id,))

import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/2_Gobiernos.shp" , "Gobierno", "Book from Cline published on 1972", "Cline", "administrative divisions", None )
#import_from_shapefile( collection_id , "decm-data/decm-polygons/78_se_frontier_gobierno.shp" , "Gobierno", "Cline 1972", Cline", "administrative divisions", None )

#rows = conn.execute("SELECT DISTINCT l2.feature_id, g_feature_name.name, l1.feature_id, g1.time_period_id from g_location_geometry g1, g_location_geometry g2, g_location l1, g_location l2, g_feature_name WHERE within(g1.encoded_geometry,g2.encoded_geometry) AND g1.location_id=l1.location_id AND g2.location_id=l2.location_id AND g_feature_name.feature_id=l2.feature_id AND g_feature_name.primary_display=1 AND g1.time_period_id=g2.time_period_id").fetchall()
#for row in rows:
#    related_feature_id = get_identifier("g_related_feature","related_feature_id")
#    conn.execute("INSERT INTO g_related_feature ( related_feature_id, feature_id, related_name, related_feature_feature_id, time_period_id, related_type_term_id ) VALUES (?,?,?,?,?,?)", (related_feature_id, row[0], row[1], row[2], row[3], 1278) )
#conn.commit()

