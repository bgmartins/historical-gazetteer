import sqlite3
import os
import shapely.wkt
import itertools
database="gazetteer.db"
if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
conn = sqlite3.connect( database )
conn.enable_load_extension(True)

relation_dict = {
    'Depends on': 1263,
    'Estancia': 1263,
    'Near': 1265,
    'Within': 1268,
    'Member is': 1269,
    'None': 1263,
    'Equal': 1276,
    'Overlap':1266,
    'Adjacent': 1265
    }

progress_status=[]

def get_identifier(table_name, column_name):
    res = conn.execute("SELECT CASE WHEN MAX(" + column_name + ") = COUNT(*) THEN MAX(" + column_name + ") + 1 WHEN MIN(" + column_name + ") > 1 THEN 1 WHEN MAX(" + column_name + ") <> COUNT(*) THEN (SELECT MIN(" + column_name + ")+1 FROM " + table_name + " WHERE (" + column_name + "+1) NOT IN (SELECT " + column_name + " FROM " + table_name + ")) ELSE 1 END FROM " + table_name)
    return res.fetchone()[0]   

def create_new_relation(feature_1, feature_2, relation_type):
    new_id=get_identifier("g_related_feature","related_feature_id")
    related_name=conn.execute("SELECT name from g_feature_name where feature_id = ? and primary_display=1 limit 1", (feature_2,)).fetchone()[0]
    conn.execute("INSERT INTO g_related_feature (related_feature_id, feature_id,related_name ,related_feature_feature_id, time_period_id, related_type_term_id,time_period_note) VALUES(?,?,?,?,2,?,NULL)", (new_id,feature_1,related_name,feature_2,relation_type))

def check_geometries_relation(feature_1, feature_2):
    id_1=feature_1["feature_id"]
    id_2=feature_2["feature_id"]
    geo_1=feature_1["geometry"]
    geo_2=feature_2["geometry"]
    if(geo_1.equals(geo_2) or geo_1.almost_equals(geo_2)):
        create_new_relation(id_1,id_2,relation_dict["Equal"])
    elif(geo_1.contains(geo_2)):
        create_new_relation(id_1,id_2,relation_dict["Member is"])
    elif(geo_1.within(geo_2)):
        create_new_relation(id_1,id_2,relation_dict["Within"])
    elif(geo_1.overlaps(geo_2)):
        create_new_relation(id_1,id_2,relation_dict["Overlap"])
    elif(geo_1.touches(geo_2)):
        create_new_relation(id_1,id_2,relation_dict["Adjacent"])
        

def process_geometries():
    raw_geometries = conn.execute("SELECT feature_id, encoded_geometry FROM g_location_geometry Natural Join g_location").fetchall()
    geometries=[]
    print("getting geometries...")
    for row in raw_geometries:
        if(row[1]!="None"):
            enc_geo = shapely.wkt.loads(row[1])
            enc_geo = enc_geo.simplify(0.1, preserve_topology=True)
            aux=shapely.geometry.mapping(enc_geo)
            geo_obj={}
            geo_obj["feature_id"]=row[0]
            geo_obj["geometry"]=enc_geo
            geometries.append(geo_obj)
    print("checking geometry relations...")
    print(len(geometries))        
    for a, b in itertools.combinations(geometries, 2):
        if(a["feature_id"] not in progress_status):
            print("Inspecting feature id: " + str(a["feature_id"]))
            progress_status.append(a["feature_id"])
        check_geometries_relation(a, b)
        check_geometries_relation(b, a)

process_geometries()

conn.commit()