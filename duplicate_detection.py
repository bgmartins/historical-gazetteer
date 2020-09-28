import itertools
import csv
import sqlite3
import os
from pyjarowinkler import distance
import shapely.wkt
import itertools
import pyproj
geod = pyproj.Geod(ellps='WGS84')

conn = sqlite3.connect("gazetteer.db")
c = conn.cursor()
raw_points=[]
progress_status=[]
source_id=1

def get_identifier(table_name, column_name):
    res = conn.execute("SELECT CASE WHEN MAX(" + column_name + ") = COUNT(*) THEN MAX(" + column_name + ") + 1 WHEN MIN(" + column_name + ") > 1 THEN 1 WHEN MAX(" + column_name + ") <> COUNT(*) THEN (SELECT MIN(" + column_name + ")+1 FROM " + table_name + " WHERE (" + column_name + "+1) NOT IN (SELECT " + column_name + " FROM " + table_name + ")) ELSE 1 END FROM " + table_name)
    return res.fetchone()[0]   

def create_duplicate_input_file():
    try:
        os.remove("duplicate_input.csv")
    except:
        pass
    data = conn.execute("select name,feature_id from g_feature_name where primary_display=1").fetchall()
    with open('duplicate_input.csv',mode='w',newline='') as duplicate_file:
        writer = csv.writer(duplicate_file, delimiter='|', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        for a, b in itertools.combinations(data, 2):
            writer.writerow([a[0],b[0]])    
            
def jaro_winkler_duplicate_processing(string1, string2):
    similarity = distance.get_jaro_distance(string1, string2, winkler=True, scaling=0.1)
    if(similarity >= 0.9):
        return True
    else:
        return False
    
def check_if_near(feature_1, feature_2):
    id_1=feature_1["feature_id"]
    id_2=feature_2["feature_id"]
    geo_1=feature_1["coordinates"]
    geo_2=feature_2["coordinates"]
    angle1,angle2,distance = geod.inv(geo_1[0], geo_1[1], geo_2[0], geo_2[1])
    if(distance<500):
        return True
    return False
    
    
def string_matching_near_processing():
    source_id = get_identifier("g_source","source_id")
    source_reference_id = get_identifier("l_source_reference","source_reference_id")
    entry_source_id = get_identifier("g_entry_source","entry_source_id")
    conn.execute("INSERT INTO l_source_reference ( source_reference_id, citation, reference_author_id ) VALUES (?,?,1)", (source_reference_id, "Relations Created During the Duplicate Detection Process") )
    conn.execute("INSERT INTO g_source ( source_id, source_mnemonic, contributor_id, source_reference_id ) VALUES (?,?,2,?)", (source_id, "Duplicate Processing", source_reference_id) )
    conn.execute("INSERT INTO g_entry_source ( entry_source_id, source_id, entry_date ) VALUES (?,?,'now')", (entry_source_id,source_id) )
    raw_geometries = conn.execute("SELECT feature_id, encoded_geometry FROM g_location_geometry Natural Join g_location").fetchall()
    geometries=[]
    print("getting geometries...")
    for row in raw_geometries:
        if(row[1]!="None"):
            enc_geo = shapely.wkt.loads(row[1])
            aux=shapely.geometry.mapping(enc_geo)
            if(aux['type']=="Point"):
                aux["feature_id"]=row[0]
                geometries.append(aux)
    print("getting near geometries...")
    near_pairs=[]        
    for a, b in itertools.combinations(geometries, 2):
        if(a["feature_id"] not in progress_status):
            print("Inspecting feature id: " + str(a["feature_id"]))
            progress_status.append(a["feature_id"])
        if(check_if_near(a,b)):
            near_pairs.append([a['feature_id'],b['feature_id']])
    for pair in near_pairs:
        try:
            name_1 = conn.execute("select name from g_feature_name where feature_id=? and primary_display=1",(pair[0],)).fetchone()[0]
            name_2 = conn.execute("select name from g_feature_name where feature_id=? and primary_display=1",(pair[1],)).fetchone()[0]
            if(jaro_winkler_duplicate_processing(name_1,name_2)):
                new_id=get_identifier("g_related_feature","related_feature_id")
                conn.execute("INSERT INTO g_related_feature (related_feature_id, feature_id,related_name ,related_feature_feature_id, time_period_id, related_type_term_id,time_period_note) VALUES(?,?,?,?,2,1278,NULL)", (new_id,pair[0],name_2,pair[1]))
                conn.execute("INSERT INTO s_related_feature (related_feature_id,time_period_id,entry_source_id) VALUES(?,1,?)",(new_id,source_id))
                new_id = get_identifier("g_related_feature","related_feature_id")
                conn.execute("INSERT INTO g_related_feature (related_feature_id, feature_id,related_name ,related_feature_feature_id, time_period_id, related_type_term_id,time_period_note) VALUES(?,?,?,?,2,1278,NULL)", (new_id,pair[1],name_1,pair[0]))
                conn.execute("INSERT INTO s_related_feature (related_feature_id,time_period_id,entry_source_id) VALUES(?,1,?)",(new_id,source_id))
        except Exception as e: 
            print(e)
            continue
    
string_matching_near_processing()
    
conn.close()