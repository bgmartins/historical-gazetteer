import os
import re
import ftfy
import geopandas
import sqlite3
import hashlib
import pandas as pd

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


# rows=conn.execute('SELECT * FROM g_collection')

# for row in rows:
#     print(row)
      
# conn.execute("SELECT load_extension('mod_spatialite')")

def get_identifier(table_name, column_name):
    res = conn.execute("SELECT CASE WHEN MAX(" + column_name + ") = COUNT(*) THEN MAX(" + column_name + ") + 1 WHEN MIN(" + column_name + ") > 1 THEN 1 WHEN MAX(" + column_name + ") <> COUNT(*) THEN (SELECT MIN(" + column_name + ")+1 FROM " + table_name + " WHERE (" + column_name + "+1) NOT IN (SELECT " + column_name + " FROM " + table_name + ")) ELSE 1 END FROM " + table_name)
    return res.fetchone()[0]        
    
def import_polygons_from_shapefile( collection_id, shp_path, attribute_name, source_desc, source_mnemonic, feature_type, date_desc,alt_names, hash_feature_id = False, dissolve = False): 
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
        # print(dir(row))
        name = ftfy.fix_text(str(row[attribute_name]).strip())
        geo = str(row["geometry"])
        bbox = row["geometry"].bounds
      
        if( (feature_type not in row) or (row[feature_type]==None)):
            type_name="populated places"
        else:
            type_name=row[feature_type]
        if type_name in type_dict:
            type_name=type_dict[type_name]
        type_id_db = conn.execute("SELECT scheme_term_id FROM l_scheme_term where term=?",(type_name,)).fetchone()
        if(type_id_db==None):
            #type_name=type_associtation(type_name)
            new_id=get_identifier("l_scheme_term","scheme_term_id")
            conn.execute("INSERT INTO l_scheme_term (scheme_term_id,scheme_id,term,external_scheme_term_id,term_order_number,term_rank_number) VALUES(?,?,?,NULL,NULL,NULL)", (new_id,12,type_name))
        classification_term_id = conn.execute("SELECT scheme_term_id FROM l_scheme_term WHERE term=? ORDER BY term_order_number, term_rank_number",(type_name,)).fetchone()[0]
        
        if hash_feature_id: 
            feature_id = int(hashlib.md5((name + " - " + geo + " - " + feature_type + " - " + source_mnemonic).encode('utf-8')).hexdigest(), 16) & 0xFFFFFFFFFFFF
        else: 
            feature_id = get_identifier("g_feature","feature_id")
        if date_desc is None: date_desc = 'undefined-historical'
        time_period_id = conn.execute("SELECT g_time_period_to_period_name.time_period_id FROM l_time_period_name, g_time_period_to_period_name WHERE l_time_period_name.time_period_name_id=g_time_period_to_period_name.time_period_name_id AND time_period_name=?",(date_desc,)).fetchone()[0]
        language_id  = conn.execute("SELECT language_id FROM l_language WHERE language_code LIKE 'SPA'").fetchone()[0]
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
        if(alt_names in row):    
            alternative_names=str(row[alt_names]).split(';')
            if(alternative_names[0]=='None'): alternative_names=[]
            for alt_name in alternative_names:
                if len(alt_name.strip()) == 0 or alt_name.strip() == name: continue
                feature_alt_name_id = get_identifier("g_feature_name","feature_name_id")
                conn.execute("INSERT INTO g_feature_name ( feature_name_id , feature_id , primary_display , language_id , transliteration_scheme_id , name ) VALUES (?,?,?,?,9,?)", ( feature_alt_name_id, feature_id, True, language_id, alt_name ) )
                conn.execute("INSERT INTO s_feature_name ( feature_name_id, name, language_id, transliteration_scheme_id, confidence_note ) VALUES (?,?,?,9,?)", (feature_alt_name_id,entry_source_id,language_id,entry_source_id) )
        if(('FID_Relate' in row) and (row['FID_Relate']!=0)):
            new_id=get_identifier("g_related_feature","related_feature_id")
            conn.execute("INSERT INTO g_related_feature (related_feature_id, feature_id,related_name ,related_feature_feature_id, time_period_id, related_type_term_id,time_period_note) VALUES(?,?,?,?,2,1263,NULL)", (new_id,type_name,'None',row['FID_Relate']))

collection_id = get_identifier("g_collection", "collection_id")
# conn.execute("INSERT INTO g_collection VALUES (?, 'New DECM Data', '')", (collection_id,))
#----------------------------------------------ACUÑA SOURCE-----------------------------------------------------------------
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_2_Antequera1.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')

import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_3_Antequera2.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_4_Tlaxcala1.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_4_Tlaxcala1_polygons.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_5_Tlaxcala2.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_5_Tlaxcala2_polygons.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_6_Mexico1.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_6_Mexico1_polygons.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_7_Mexico2.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_7_Mexico2_polygons.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_8_Mexico3.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_8_Mexico3_polygons.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_9_Michoacan.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/Acuna_10_NuevaGalicia.shp","Placename","Book Acuña","Acuña","Type",None,'Alt_names')

#-----------------------------------------DLG SOURCE-----------------------------------------------------------------------------
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/DLG_Yucatan.shp","Placename","Book DLG","DLG","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/DPYT_Suma.shp","Placename","Book DLG","DLG","Type",None,'Alt_names')
import_polygons_from_shapefile(collection_id,"decm-data/Primary Sources/DPYT_Suma_Text.shp","Placename","Book DLG","DLG","Type",None,'Alt_names')

#-----------------------------------------Secondary------------------------------------------------------------------------
import_polygons_from_shapefile(collection_id,"decm-data/Secondary Sources/Gerhard_NewSpain.shp","Placename","Book DLG","DLG","Type",None,"Alt_names")
import_polygons_from_shapefile(collection_id,"decm-data/Secondary Sources/Gerhard_SEFrontier.shp","Placename","Book DLG","DLG","Type",None,"Alt_names")
import_polygons_from_shapefile(collection_id,"decm-data/Secondary Sources/Gerhard_SEFrontier_polygons.shp","Placename","Book DLG","DLG","Type",None,"Alt_names")
import_polygons_from_shapefile(collection_id,"decm-data/Secondary Sources/MorenoToscano.shp","Placename","Book DLG","DLG","Type",None,"Alt_names")

#------------------------------------------Tabular Sources--------------------------------------------------------------------------------------

# rows = conn.execute("SELECT DISTINCT l2.feature_id, g_feature_name.name, l1.feature_id, g1.time_period_id from g_location_geometry g1, g_location_geometry g2, g_location l1, g_location l2, g_feature_name WHERE within(g1.encoded_geometry,g2.encoded_geometry) AND g1.location_id=l1.location_id AND g2.location_id=l2.location_id AND g_feature_name.feature_id=l2.feature_id AND g_feature_name.primary_display=1 AND g1.time_period_id=g2.time_period_id").fetchall()
# for row in rows:
#     related_feature_id = get_identifier("g_related_feature","related_feature_id")
#     conn.execute("INSERT INTO g_related_feature ( related_feature_id, feature_id, related_name, related_feature_feature_id, time_period_id, related_type_term_id ) VALUES (?,?,?,?,?,?)", (related_feature_id, row[0], row[1], row[2], row[3], 1278) )

# polygon = conn.execute("SELECT AsGeoJSON(ST_Boundary(ST_Union(encoded_geometry))) FROM g_location_geometry").fetchone()[0]
# with open('covered-region.geojson', 'w') as outfile: json.dump(polygon, outfile)

conn.commit()
# print(type_dict)
print("DONE")