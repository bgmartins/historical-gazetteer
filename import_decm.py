import os
import re
import ftfy
import geopandas
from pandas import read_excel
import sqlite3
import hashlib
import pandas as pd
import math



database = "gazetteer.db"
if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
conn = sqlite3.connect( database )
conn.enable_load_extension(True)
type_dict={
    'Estancia': 'resorts',
     'Sujeto': 'populated places',#????????????????
     'Pueblo': 'towns',
     'Alcaldia Mayor': 'buildings',
     'Villa': 'villas',
     'Pueblo comarcano': 'towns',
     'Cabecera': 'headquarters',
     'River': 'rivers',
     'Shrine': 'shrines',
     'Harbor': 'harbours',
     'City': 'cities',
     'Hill': 'hills',
     'Corregimiento': 'townships',
     'Church': 'churches',
     'Mountain Range': 'mountain ranges',
     'Coast': 'coasts',
     'Mining Camp': 'mining camps',
     'Valley': 'valleys',
     'Sea': 'seas',
     'Cave': 'caves',
     'Volcano': 'volcanoes',
     'Barrio': 'neighborhoods (residential)',
     'Lake': 'lakes',
     'Island': 'islands',
     'Source': 'populated places',#??????????
     'Bridge': 'bridges',
     'Cathedral': 'cathedrals',
     'Chapel': 'chapels',
     'Monastery': 'monasteries',
     'Region': 'regions',
     'Town': 'towns',
     'Collegue': 'colleges',
     'Pyramid': 'pyramids',
     'Inn': 'inns',
     'Parish': 'parishes',
     'Market': 'markets',
     'Convent': 'convents',
     'Imaginary': 'populated places',
     'Province': 'provinces',
     'Fortress': 'fortifications',
     'Beneficio': 'populated places',
     'Cabeza': 'headquarters',
     'Water source': 'water wells',
     'Gulf': 'gulfs',
     'Cliff': 'cliffs',
     'Oyster bed': 'animal pounds',
     'Reef': 'reefs',
     'Aztec garrison': 'historical sites',
     'Bodega': 'warehouses',
     'Dune': 'dunes',
     'Plain': 'plains',
     'Mining camp': 'mining camps',
     'Spring': 'springs (hydrographic)',
     'Chaplaincy': 'community centers',
     'Salt pan': 'salt ponds',
     'Local Market': 'markets',
     'Kingdom': 'populated places',#????????????????????
     'Building': 'buildings',
     'School': 'schools',
     'Houses of pleasure': 'populated places',
     'Estuary': 'estuaries',
     'Isthmus': 'isthmuses',
     'MIning Camp': 'mining camps',
     'Political area': 'political areas',
     'Hacienda': 'estates',
     'Stream': 'streams'
    }

relation_dict = {
    'Depends on': 1263,
    'Estancia': 1263,
    'Near': 1265,
    'Within': 1268,
    'None': 1263
    }


# rows=conn.execute('SELECT * FROM g_collection')

# for row in rows:
#     print(row)
      
# conn.execute("SELECT load_extension('mod_spatialite')")

def get_identifier(table_name, column_name):
    res = conn.execute("SELECT CASE WHEN MAX(" + column_name + ") = COUNT(*) THEN MAX(" + column_name + ") + 1 WHEN MIN(" + column_name + ") > 1 THEN 1 WHEN MAX(" + column_name + ") <> COUNT(*) THEN (SELECT MIN(" + column_name + ")+1 FROM " + table_name + " WHERE (" + column_name + "+1) NOT IN (SELECT " + column_name + " FROM " + table_name + ")) ELSE 1 END FROM " + table_name)
    return res.fetchone()[0]    

def import_features_from_tabular(collection_id,filename,source_desc,source_mnemonic,placename,alt_names, feature_type, sheetname, id_tag, related_tag):
    file=pd.ExcelFile(filename)
    id_dict={}
    source_id = get_identifier("g_source","source_id")
    source_reference_id = get_identifier("l_source_reference","source_reference_id")
    entry_source_id = get_identifier("g_entry_source","entry_source_id")
    conn.execute("INSERT INTO l_source_reference ( source_reference_id, citation, reference_author_id ) VALUES (?,?,1)", (source_reference_id, source_desc) )
    conn.execute("INSERT INTO g_source ( source_id, source_mnemonic, contributor_id, source_reference_id ) VALUES (?,?,2,?)", (source_id, source_mnemonic, source_reference_id) )
    conn.execute("INSERT INTO g_entry_source ( entry_source_id, source_id, entry_date ) VALUES (?,?,'now')", (entry_source_id,source_id) )
    if (sheetname in file.sheet_names):
        df = read_excel(filename, sheetname)
    else:
        df = read_excel(filename)
    print("importing: ")
    print(filename)
    for row in range(df[placename].size):
        name=df[placename][row]
        type_name="populated places"
        if(feature_type in df):
            type_name=df[feature_type][row]
        if type_name in type_dict:
            type_name=type_dict[type_name]
        else:
            type_name="populated places"
        type_id_db = conn.execute("SELECT scheme_term_id FROM l_scheme_term where term=?",(type_name,)).fetchone()
        entry_source_id = get_identifier("g_entry_source","entry_source_id")
        classification_term_id = conn.execute("SELECT scheme_term_id FROM l_scheme_term WHERE term=? ORDER BY term_order_number, term_rank_number",(type_name,)).fetchone()[0]
        date_desc = 'undefined-historical'
        time_period_id = conn.execute("SELECT g_time_period_to_period_name.time_period_id FROM l_time_period_name, g_time_period_to_period_name WHERE l_time_period_name.time_period_name_id=g_time_period_to_period_name.time_period_name_id AND time_period_name=?",(date_desc,)).fetchone()[0]
        feature_id = get_identifier("g_feature","feature_id")
        if(id_tag in df): id_dict[df[id_tag][row]]=feature_id
        feature_name_id = get_identifier("g_feature_name","feature_name_id")
        language_id  = conn.execute("SELECT language_id FROM l_language WHERE language_code LIKE 'SPA'").fetchone()[0]
        location_id = get_identifier("g_location","location_id")        
        location_geometry_id = get_identifier("g_location_geometry","location_geometry_id")
        classification_id = get_identifier("g_classification","classification_id")
        conn.execute("INSERT INTO g_name_to_link_info_reference (feature_name_id,source_reference_id,pages) VALUES(?,?,0)",(feature_name_id,source_reference_id))
        conn.execute("INSERT INTO g_feature ( feature_id , collection_id , is_complete , time_period_id , entry_note , entry_date , modification_date ) VALUES (?,?,?,?,'none','now','now')", ( feature_id, collection_id, True, time_period_id) )
        conn.execute("INSERT INTO g_feature_name ( feature_name_id , feature_id , primary_display , language_id , transliteration_scheme_id , name ) VALUES (?,?,?,?,9,?)", ( feature_name_id, feature_id, True, language_id, name ) )
        conn.execute("INSERT INTO g_classification ( classification_id, feature_id, classification_term_id, primary_display, time_period_id ) VALUES (?,?,?,?,?)", (classification_id, feature_id, classification_term_id, True, time_period_id))    
        conn.execute("INSERT INTO s_feature ( feature_id, time_period_id, entry_source_id ) VALUES (?,?,?)", (feature_id, time_period_id, entry_source_id) )
        conn.execute("INSERT INTO s_feature_name ( feature_name_id, name, language_id, transliteration_scheme_id, confidence_note ) VALUES (?,?,?,9,?)", (feature_name_id,entry_source_id,language_id,entry_source_id) )
        conn.execute("INSERT INTO s_classification ( classification_id, classification_term_id, time_period_id, entry_source_id ) VALUES (?,?,?,?)", (classification_id,entry_source_id,entry_source_id,entry_source_id) )
        if((alt_names in df) and (not pd.isnull(df[alt_names][row]))):
            alternatives = df[alt_names][row].split(";")
            for alt_name in alternatives:
                if len(alt_name.strip()) == 0 or alt_name.strip() == name: continue
                feature_alt_name_id = get_identifier("g_feature_name","feature_name_id")
                conn.execute("INSERT INTO g_feature_name ( feature_name_id , feature_id , primary_display , language_id , transliteration_scheme_id , name ) VALUES (?,?,?,?,9,?)", ( feature_alt_name_id, feature_id, False, language_id, alt_name ) )
                conn.execute("INSERT INTO s_feature_name ( feature_name_id, name, language_id, transliteration_scheme_id, confidence_note ) VALUES (?,?,?,9,?)", (feature_alt_name_id,entry_source_id,language_id,entry_source_id) )
    print("creating relations...")
    for row in range(df[placename].size):
        if((related_tag in df) and (df[related_tag][row]!=0)):
            if(df[related_tag][row] in id_dict):
                new_id=get_identifier("g_related_feature","related_feature_id")
                db_id=id_dict[df[id_tag][row]]
                related_id=id_dict[df[related_tag][row]]
                related_name=conn.execute("SELECT name from g_feature_name where feature_id = ? limit 1", (related_id,)).fetchone()[0]
                conn.execute("INSERT INTO g_related_feature (related_feature_id, feature_id,related_name ,related_feature_feature_id, time_period_id, related_type_term_id,time_period_note) VALUES(?,?,?,?,2,1263,NULL)", (new_id,db_id,related_name,related_id))

def import_polygons_from_shapefile( collection_id, shp_path, attribute_name, source_desc, source_mnemonic, feature_type, date_desc, alt_names, related_tag, relation_type_tag, id_tag, hash_feature_id = False, dissolve = False): 
    id_dict={}
    source_id = get_identifier("g_source","source_id")
    source_reference_id = get_identifier("l_source_reference","source_reference_id")
    entry_source_id = get_identifier("g_entry_source","entry_source_id")
    conn.execute("INSERT INTO l_source_reference ( source_reference_id, citation, reference_author_id ) VALUES (?,?,1)", (source_reference_id, source_desc) )
    conn.execute("INSERT INTO g_source ( source_id, source_mnemonic, contributor_id, source_reference_id ) VALUES (?,?,2,?)", (source_id, source_mnemonic, source_reference_id) )
    conn.execute("INSERT INTO g_entry_source ( entry_source_id, source_id, entry_date ) VALUES (?,?,'now')", (entry_source_id,source_id) )
    data = geopandas.read_file(shp_path, encoding='utf8')
    print("importing: ")
    print(shp_path)
    if dissolve:
        data = data[[attribute_name, 'geometry']]
        data = data.dissolve(by=attribute_name).reset_index()
    for index, row in data.iterrows():
        name = ftfy.fix_text(str(row[attribute_name]).strip())
        geo = str(row["geometry"])
        # print(geo)
        if(geo!="None"):
            bbox = row["geometry"].bounds
        else:
            bbox=[0,0,0,0]
      
        if( (feature_type not in row) or (row[feature_type]==None)):
            type_name="populated places"
        else:
            type_name=row[feature_type]
        if type_name in type_dict:
            type_name=type_dict[type_name]
        type_id_db = conn.execute("SELECT scheme_term_id FROM l_scheme_term where term=?",(type_name,)).fetchone()
        if(type_id_db==None):
            new_id=get_identifier("l_scheme_term","scheme_term_id")
            conn.execute("INSERT INTO l_scheme_term (scheme_term_id,scheme_id,term,external_scheme_term_id,term_order_number,term_rank_number) VALUES(?,?,?,NULL,NULL,NULL)", (new_id,12,type_name))
        classification_term_id = conn.execute("SELECT scheme_term_id FROM l_scheme_term WHERE term=? ORDER BY term_order_number, term_rank_number",(type_name,)).fetchone()[0]
        
        if hash_feature_id: 
            feature_id = int(hashlib.md5((name + " - " + geo + " - " + feature_type + " - " + source_mnemonic).encode('utf-8')).hexdigest(), 16) & 0xFFFFFFFFFFFF
        else: 
            feature_id = get_identifier("g_feature","feature_id")
        if(id_tag in row): id_dict[row[id_tag]]=feature_id
        if date_desc is None: date_desc = 'undefined-historical'
        time_period_id = conn.execute("SELECT g_time_period_to_period_name.time_period_id FROM l_time_period_name, g_time_period_to_period_name WHERE l_time_period_name.time_period_name_id=g_time_period_to_period_name.time_period_name_id AND time_period_name=?",(date_desc,)).fetchone()[0]
        language_id  = conn.execute("SELECT language_id FROM l_language WHERE language_code LIKE 'SPA'").fetchone()[0]
        feature_name_id = get_identifier("g_feature_name","feature_name_id")
        location_id = get_identifier("g_location","location_id")        
        location_geometry_id = get_identifier("g_location_geometry","location_geometry_id")
        classification_id = get_identifier("g_classification","classification_id")
        conn.execute("INSERT INTO g_name_to_link_info_reference (feature_name_id,source_reference_id,pages) VALUES(?,?,0)",(feature_name_id,source_reference_id))
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
        if(alt_names in row):    
            alternative_names=str(row[alt_names]).split(';')
            if(alternative_names[0]=='None'): alternative_names=[]
            for alt_name in alternative_names:
                if len(alt_name.strip()) == 0 or alt_name.strip() == name: continue
                feature_alt_name_id = get_identifier("g_feature_name","feature_name_id")
                conn.execute("INSERT INTO g_feature_name ( feature_name_id , feature_id , primary_display , language_id , transliteration_scheme_id , name ) VALUES (?,?,?,?,9,?)", ( feature_alt_name_id, feature_id, False, language_id, alt_name ) )
                conn.execute("INSERT INTO s_feature_name ( feature_name_id, name, language_id, transliteration_scheme_id, confidence_note ) VALUES (?,?,?,9,?)", (feature_alt_name_id,entry_source_id,language_id,entry_source_id) )
    print("creating relations...") 
    for index, row in data.iterrows():
        if((related_tag in row) and (row[related_tag]!=0)):
            relation_type_id=1263
            if(relation_type_tag in row and row[relation_type_tag] in relation_dict):
                relation_type_id=relation_dict[row[relation_type_tag]]
            if(row[related_tag] in id_dict):
                new_id=get_identifier("g_related_feature","related_feature_id")
                db_id=id_dict[row[id_tag]]
                related_id=id_dict[row[related_tag]]
                related_name=conn.execute("SELECT name from g_feature_name where feature_id = ? limit 1", (related_id,)).fetchone()[0]
                conn.execute("INSERT INTO g_related_feature (related_feature_id, feature_id,related_name ,related_feature_feature_id, time_period_id, related_type_term_id,time_period_note) VALUES(?,?,?,?,2,?,NULL)", (new_id,db_id,related_name,related_id,relation_type_id))

def show_shp_info(shp_path):  
    data = geopandas.read_file(shp_path, encoding='utf8')
    print("importing: ")
    print(shp_path)
    for index, row in data.iterrows():
        #print(dir(row))
        print(row['Relation'])

def show_excel_info(filename):  
    file=pd.ExcelFile(filename)
    df = read_excel(filename)
    print(dir(df))
        
collection_id = get_identifier("g_collection", "collection_id")
# conn.execute("INSERT INTO g_collection VALUES (?, 'New DECM Data', '')", (collection_id,))

# show_shp_info("decm-data/Primary Sources/Acuna_2_Antequera1.shp")

#----------------------------------------------ADDITIONAL DATA--------------------------------------------------------------
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/2_Gobiernos.shp","Placename","Cline 1972 - 2_Gobiernos","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/6_Audiencias.shp","Placename","Cline 1972 - 6_Audiencias","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/7_Dioceses.shp","Placename","Cline 1972 - 7_Dioceses","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/10_ethnohistorical_regions.shp","Placename","Cline 1972 - 10_ethnohistorical_regions","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/12_provincias_1570.shp","Placename","Cline 1972 - 12_provincias_1570","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/58_gerhard_dioceses.shp","Placename","Cline 1972 - 58_gerhard_dioceses","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/63_roys_yucatan_provincias.shp","Placename","Cline 1972 - 63_roys_yucatan_provincias","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/66_H_III_I_A_provincias.shp","Placename","Cline 1972 - 66_H_III_I_A_provincias","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/67_H_III_1_B_audiencias.shp","Placename","Cline 1972 - 67_H_III_1_B_audiencias","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/68_H_II_3_senorios.shp","Placename","Cline 1972 - 68_H_II_3_senorios","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/69_H_II_2_entidades_politicas.shp","Placename","Cline 1972 - 69_H_II_2_entidades_politicas","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/70_H_III_1_C_eclesiastica.shp","Placename","Cline 1972 - 70_H_III_1_C_eclesiastica","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/72_H_II_2_inset.shp","Placename","Cline 1972 - 72_H_II_2_inset","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/73_texcoco_lago.shp","Placename","Cline 1972 - 73_texcoco_lago","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/76_se_frontier_subdelegacion.shp","Placename","Cline 1972 - 76_se_frontier_subdelegacion","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/77_se_frontier_intendancy.shp","Placename","Cline 1972 - 77_se_frontier_intendancy","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/78_se_frontier_gobierno.shp","Placename","Cline 1972 - 78_se_frontier_gobierno","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/79_se_frontier_audiencia.shp","Placename","Cline 1972 - 79_se_frontier_audiencia","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/80_se_frontier_control_limits.shp","Placename","Cline 1972 - 80_se_frontier_control_limits","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Additional Data/87_civil_divisions_1580.shp","Placename","Cline 1972 - 87_civil_divisions_1580","Cline","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')

#--------------------------------------------PRIMARY SOURCES----------------------------------------------------------------
#----------------------------------------------ACUÑA SOURCE-----------------------------------------------------------------
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_2_Antequera1.shp","Placename","Book Acuña - Acuna_2_Antequera1","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID2')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_3_Antequera2.shp","Placename","Book Acuña - Acuna_3_Antequera2","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID3')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_4_Tlaxcala1.shp","Placename","Book Acuña - Acuna_4_Tlaxcala1","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID4')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_4_Tlaxcala1_polygons.shp","Placename","Book Acuña - Acuna_4_Tlaxcala1_polygons","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID4')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_5_Tlaxcala2.shp","Placename","Book Acuña - Acuna_5_Tlaxcala2","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID5')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_5_Tlaxcala2_polygons.shp","Placename","Book Acuña - Acuna_5_Tlaxcala2_polygons","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID5')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_6_Mexico1.shp","Placename","Book Acuña - Acuna_6_Mexico1","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID6')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_6_Mexico1_polygons.shp","Placename","Book Acuña - Acuna_6_Mexico1_polygons","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID6')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_7_Mexico2.shp","Placename","Book Acuña - Acuna_7_Mexico2","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID7')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_7_Mexico2_polygons.shp","Placename","Book Acuña - Acuna_7_Mexico2_polygons","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID7')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_8_Mexico3.shp","Placename","Book Acuña - Acuna_8_Mexico3","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID8')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_8_Mexico3_polygons.shp","Placename","Book Acuña - Acuna_8_Mexico3_polygons","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID8')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_9_Michoacan.shp","Placename","Book Acuña - Acuna_9_Michoacan","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID9')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_10_NuevaGalicia.shp","Placename","Book Acuña - Acuna_10_NuevaGalicia","Acuña","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID10')

# #-----------------------------------------DLG SOURCE-----------------------------------------------------------------------------
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/DLG_Yucatan.shp","Placename","Book DLG - DLG_Yucatan","DLG","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID_Yuc')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/DPYT_Suma.shp","Placename","Book DLG - DPYT_Suma","DLG","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID_Sum')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/DPYT_Suma_Text.shp","Placename","Book DLG - DPYT_Suma_Text","DLG","Type",None,'Alt_names','FID_Relate',"Relation",'My_FID_txt')

# #-----------------------------------------Secondary------------------------------------------------------------------------
import_polygons_from_shapefile(collection_id,"decm-data/Secondary Sources/Gerhard_NewSpain.shp","Placename","Gerhard 1972 - Gerhard_NewSpain","Gerhard","Type",None,"Alt_names",'FID_Relate',"Relation",'My_FID_NS')
import_polygons_from_shapefile(collection_id,"decm-data/Secondary Sources/Gerhard_SEFrontier.shp","Placename","Gerhard 1972 - SEFrontier","Gerhard","Type",None,"Alt_names",'FID_Relate',"Relation",'My_FID_SE')
import_polygons_from_shapefile(collection_id,"decm-data/Secondary Sources/Gerhard_SEFrontier_polygons.shp","Placename","Gerhard 1972 - Gerhard_SEFrontier_polygons","Gerhard","Type",None,"Alt_names",'FID_Relate',"Relation",'My_FID_SE')
import_polygons_from_shapefile(collection_id,"decm-data/Secondary Sources/MorenoToscano.shp","Placename","Moreno Toscano 1968","Toscano","Type",None,"Alt_names",'FID_Relate',"Relation",'My_FID_MT')

#------------------------------------------Tabular Sources--------------------------------------------------------------------------------------
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/1_Acuña_Guatemala_Index.xlsx","1_Acuña_Guatemala_Index","Acuña","name","alt_names",None,"NOT_FOUND","My_FID1","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/2_Acuña_Antequera1.xlsx","2_Acuña_Antequera1","Acuña","PlaceName","Alt_names","Type","NOT_FOUND","My_FID2","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/3_Acuña_Antequera2.xlsx","3_Acuña_Antequera2","Acuña","PlaceName","Alt_names","Type","NOT_FOUND","My_FID3","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/4_Acuña_Tlaxcala1.xlsx","4_Acuña_Tlaxcala1","Acuña","PlaceName","Alt_names","Type","NOT FOUND","My_FID4","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/5_Acuna_Tlaxcala2.xlsx","5_Acuna_Tlaxcala2","Acuña","Placename","Alt_names","Type","NOT FOUND","My_FID5","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/6_Acuna_Mexico1.xlsx","6_Acuna_Mexico1","Acuña","PlaceName","Alt_names","Type","NOTFOUND","My_FID6","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/7_Acuna_Mexico2.xlsx","7_Acuna_Mexico2","Acuña","PlaceName","Alt_names","Type","NOT FOUND","My_FID7","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/8_Acuna_Mexico3.xlsx","8_Acuna_Mexico3","Acuña","Placename","Alt_names","Type","Not_Found","My_FID8","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/9_Acuna_Michoacan.xlsx","9_Acuna_Michoacan","Acuña","PlaceName","Alt_names","Type","NOT FOUND","My_FID9","Related_Feature_ID")
import_features_from_tabular(collection_id,"decm-data/Tabular Sources/10_Acuna_NuevaGalicia.xlsx","10_Acuna_NuevaGalicia","Acuña","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/cline_1964_1972_relaciones_status.xlsx","Cline 1964 - Relaciones Status","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/cline_1972_archdioceses.xlsx","Cline 1972 - Archdioceses","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/cline_1972_colonial_jurisdictions.xlsx","Cline 1972 - Colonial Jurisdictions","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/cline_1972_ethnohistorical_regions.xlsx","Cline 1972 - Ethnohistorical Regions","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/cline_1972_rg_repositories.xlsx","Cline 1972 - Rg Repositories","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/Count_municip-states.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/DeLa_Garza_Yucatan_Index2.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/DeLa_Garza_Yucatán_RG_status.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/DeLaGarza_Index_Yucatan.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/DelPasoYTroncoso_Suma_Index.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/Echenique_pictogramas_codices.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/Echenique_relaciones.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/garcia_cubas_diccionario_historico.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/Gerhard1972_AGuide_Index.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/Gerhard1972_SE_Frontier_Index.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/harvey_language_index.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/harvey_language_index_census.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/harvey_language_index_RG.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/MorenoToscano1968_Index.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")
# import_features_from_tabular(collection_id,"decm-data/Tabular Sources/starr_aztec_place-names.xlsx","cline_1964_1972_relaciones_status.xlsx","Cline","PlaceName","Alt_names","Type","NOT FOUND","My_FID10","Related_Feature_ID")

# rows = conn.execute("SELECT DISTINCT l2.feature_id, g_feature_name.name, l1.feature_id, g1.time_period_id from g_location_geometry g1, g_location_geometry g2, g_location l1, g_location l2, g_feature_name WHERE within(g1.encoded_geometry,g2.encoded_geometry) AND g1.location_id=l1.location_id AND g2.location_id=l2.location_id AND g_feature_name.feature_id=l2.feature_id AND g_feature_name.primary_display=1 AND g1.time_period_id=g2.time_period_id").fetchall()
# for row in rows:
#     related_feature_id = get_identifier("g_related_feature","related_feature_id")
#     conn.execute("INSERT INTO g_related_feature ( related_feature_id, feature_id, related_name, related_feature_feature_id, time_period_id, related_type_term_id ) VALUES (?,?,?,?,?,?)", (related_feature_id, row[0], row[1], row[2], row[3], 1278) )

# polygon = conn.execute("SELECT AsGeoJSON(ST_Boundary(ST_Union(encoded_geometry))) FROM g_location_geometry").fetchone()[0]
# with open('covered-region.geojson', 'w') as outfile: json.dump(polygon, outfile)

conn.commit()
# print(type_dict)
print("DONE")