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

def import_polygons_from_shapefile( collection_id, shp_path, attribute_name, source_desc, source_mnemonic, feature_type, date_desc, dissolve = False, alt_names=[] ): 
    source_id = get_identifier("g_source","source_id")
    source_reference_id = get_identifier("l_source_reference","source_reference_id")
    entry_source_id = get_identifier("g_entry_source","entry_source_id")  
    conn.execute("INSERT INTO l_source_reference ( source_reference_id, citation, reference_author_id ) VALUES (?,?,1)", (source_reference_id, source_desc) )
    conn.execute("INSERT INTO g_source ( source_id, source_mnemonic, contributor_id, source_reference_id ) VALUES (?,?,2,?)", (source_id, source_mnemonic, source_reference_id) )
    conn.execute("INSERT INTO g_entry_source ( entry_source_id, source_id, entry_date ) VALUES (?,?,'now')", (entry_source_id,source_id) )
    data = geopandas.read_file(shp_path, encoding='utf8')
    if dissolve:
        data = data[[attribute_name, 'geometry']]
        data = data.dissolve(by=attribute_name).reset_index()
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
        conn.execute("INSERT INTO g_feature ( feature_id , collection_id , is_complete , time_period_id , entry_note , entry_date , modification_date ) VALUES (?,?,?,?,?,'now','now')", ( feature_id, collection_id, True, time_period_id, source_desc ) )
        conn.execute("INSERT INTO g_feature_name ( feature_name_id , feature_id , primary_display , language_id , transliteration_scheme_id , name ) VALUES (?,?,?,?,9,?)", ( feature_name_id, feature_id, True, language_id, name ) )
        conn.execute("INSERT INTO g_location ( location_id , feature_id , planet , bounding_box_geodetic , west_coordinate , east_coordinate , south_coordinate , north_coordinate , bounding_box_method , bounding_box_source_type ) VALUES (?,?,'Earth','EPSG:4019',?,?,?,?,'Bounding box computed from feature polygon', 'All' )", ( location_id, feature_id, bbox[0], bbox[2], bbox[1], bbox[3] ) )
        conn.execute("INSERT INTO g_location_geometry ( location_geometry_id, location_id, primary_geometry, local_geometry, geometry_coding_scheme_id, encoded_geometry, time_period_id ) VALUES (?,?,?,?,13,?,?)", (location_geometry_id, location_id, True, True, geo, time_period_id ) )
        conn.execute("INSERT INTO g_classification ( classification_id, feature_id, classification_term_id, primary_display, time_period_id ) VALUES (?,?,?,?,?)", (classification_id, feature_id, classification_term_id, True, time_period_id))
        conn.execute("INSERT INTO s_feature ( feature_id, time_period_id, entry_source_id ) VALUES (?,?,?)", (feature_id, time_period_id, entry_source_id) )
        conn.execute("INSERT INTO s_location ( location_id , bounding_box_source_entry_id ) VALUES (?,?)", (location_id,entry_source_id) )
        conn.execute("INSERT INTO s_location_geometry ( location_geometry_id, time_period_id, entry_source_id ) VALUES (?,?,?)", (location_geometry_id,time_period_id,entry_source_id) )
        conn.execute("INSERT INTO s_feature_name ( feature_name_id, name, language_id, transliteration_scheme_id, confidence_note ) VALUES (?,?,?,9,?)", (feature_name_id,entry_source_id,language_id,entry_source_id) )
        conn.execute("INSERT INTO s_classification ( classification_id, classification_term_id, time_period_id, entry_source_id ) VALUES (?,?,?,?)", (classification_id,entry_source_id,entry_source_id,entry_source_id) )
        alternative_names = ""
        for i in alt_names: alternative_names = alternative_names + " , " + ftfy.fix_text(str(row[alt_names]))
        for alt_name in re.split(" *[;,] *", alternative_names):
            if len(alt_name.strip()) == 0 or alt_name.strip() == name: continue
            feature_alt_name_id = get_identifier("g_feature_name","feature_name_id")
            conn.execute("INSERT INTO g_feature_name ( feature_name_id , feature_id , primary_display , language_id , transliteration_scheme_id , name ) VALUES (?,?,?,?,9,?)", ( feature_alt_name_id, feature_id, True, language_id, alt_name ) )
            conn.execute("INSERT INTO s_feature_name ( feature_name_id, name, language_id, transliteration_scheme_id, confidence_note ) VALUES (?,?,?,9,?)", (feature_alt_name_id,entry_source_id,language_id,entry_source_id) )
        conn.commit()

collection_id = get_identifier("g_collection", "collection_id")
conn.execute("INSERT INTO g_collection VALUES (?, 'DECM Data', '')", (collection_id,))

import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/2_Gobiernos.shp" , "Gobierno", "Book from Cline published on 1972", "Cline", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/6_Audiencias.shp" , "Audiencia", "Book from Cline published on 1972", "Cline", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/6_Audiencias_capitals.shp" , "Audiencia", "Book from Cline published on 1972", "Cline", "capitals", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/7_Dioceses.shp" , "Diocese", "Book from Cline published on 1972", "Cline", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/7_Dioceses_Bishopric.shp" , "Name", "Book from Cline published on 1972", "Cline", "capitals", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/10_ethnohistorical_regions.shp" , "region", "Book from Cline published on 1972", "Cline", "subdivisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/12_provincias_1570.shp" , "Provincia", "Book from Gerhard published on 1972a", "Gerhard", "provinces", None )
#import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/58_gerhard_dioceses.shp" , "Diocese", "Book from Gerhard published on 1972b", "Gerhard", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/59_gerhard_minor_divisions_1786.shp" , "name", "Book from Gerhard published on 1972a", "Gerhard", "subdivisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/60_gerhard_subgobierno_1786.shp" , "Gobierno", "Book from Gerhard published on 1972a", "Gerhard", "subdivisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/61_gerhard_NE_1786.shp" , "gobierno", "Book from Gerhard published on 1972a", "Gerhard", "regions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/62_gerhard_intendancies_1786.shp" , "Residence", "Book from Gerhard published on 1972a", "Gerhard", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/63_roys_yucatan_provincias.shp" , "region", "Book from Vargas published on 2015", "Vargas", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/66_H_III_I_A_provincias.shp" , "Provincia", "Information from Instituto de Geografia - Universidad Nacional Autonoma de Mexico", "IG-UNAM", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/67_H_III_1_B_audiencias.shp" , "audiencia", "Information from Instituto de Geografia - Universidad Nacional Autonoma de Mexico", "IG-UNAM", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/68_H_II_3_senorios.shp" , "org_name", "Information from Instituto de Geografia - Universidad Nacional Autonoma de Mexico", "IG-UNAM", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/69_H_II_2_entidades_politicas.shp" , "entidad", "Information from Instituto de Geografia - Universidad Nacional Autonoma de Mexico", "IG-UNAM", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/70_H_III_1_C_eclesiastica.shp" , "ordenes_re", "Information from Instituto de Geografia - Universidad Nacional Autonoma de Mexico", "IG-UNAM", "administrative divisions", None )
#import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/72_H_II_2_inset.shp" , "entidad", "Information from Instituto de Geografia - Universidad Nacional Autonoma de Mexico", "IG-UNAM", "regions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/73_texcoco_lago.shp" , "entity", "Arqueología Mexicana", "?????", "regions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/76_se_frontier_subdelegacion.shp" , "name", "Book from Gerhard published on 1979", "Gerhard", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/76_se_frontier_subdelegacion.shp" , "gobierno", "Book from Gerhard published on 1979", "Gerhard", "administrative divisions", None , dissolve = True)
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/77_se_frontier_intendancy.shp" , "intendancy", "Book from Gerhard published on 1979", "Gerhard", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/78_se_frontier_gobierno.shp" , "gobierno", "Book from Gerhard published on 1979", "Gerhard", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/79_se_frontier_audiencia.shp" , "audiencia", "Book from Gerhard published on 1979", "Gerhard", "administrative divisions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/80_se_frontier_control_limits.shp" , "region", "Book from Gerhard published on 1979", "Gerhard", "regions", None )
import_polygons_from_shapefile( collection_id , "decm-data/decm-polygons/87_civil_divisions_1580.shp" , "chief_town", "Book from Gerhard published on 1972b", "Gerhard", "administrative divisions", None )

import_polygons_from_shapefile( collection_id , "decm-data/decm-points/Garza.shp" , "Placename", "Book Garza", "Garza", "localities", None, ['Alt_names', 'ModernName'] )
import_polygons_from_shapefile( collection_id , "decm-data/decm-points/Gerhard_North.shp" , "Placename", "Book Gerhard_North", "Gerhard_North", "localities", None, ['Alt_names', 'ModernName'] )
import_polygons_from_shapefile( collection_id , "decm-data/decm-points/Gerhard_South.shp" , "Placename", "Book Gerhard_South", "Gerhard_South", "localities", None, ['Alt_names', 'ModernName'] )
import_polygons_from_shapefile( collection_id , "decm-data/decm-points/Suma.shp" , "Placename", "Book Suma", "Suma", "localities", None, ['Alt_names', 'ModernName'] )
import_polygons_from_shapefile( collection_id , "decm-data/decm-points/Suma_txt.shp" , "Placename", "Book Suma txt", "Suma txt", "localities", None, ['Alt_names', 'ModernName'] )

#rows = conn.execute("SELECT DISTINCT l2.feature_id, g_feature_name.name, l1.feature_id, g1.time_period_id from g_location_geometry g1, g_location_geometry g2, g_location l1, g_location l2, g_feature_name WHERE within(g1.encoded_geometry,g2.encoded_geometry) AND g1.location_id=l1.location_id AND g2.location_id=l2.location_id AND g_feature_name.feature_id=l2.feature_id AND g_feature_name.primary_display=1 AND g1.time_period_id=g2.time_period_id").fetchall()
#for row in rows:
#    related_feature_id = get_identifier("g_related_feature","related_feature_id")
#    conn.execute("INSERT INTO g_related_feature ( related_feature_id, feature_id, related_name, related_feature_feature_id, time_period_id, related_type_term_id ) VALUES (?,?,?,?,?,?)", (related_feature_id, row[0], row[1], row[2], row[3], 1278) )
#conn.commit()

#polygon = conn.execute("SELECT AsGeoJSON(ST_Boundary(ST_Union(encoded_geometry))) FROM g_location_geometry").fetchone()[0]
#with open('covered-region.geojson', 'w') as outfile: json.dump(polygon, outfile)
