import os
import sqlite3
import shapely.wkt
from osgeo import ogr

database="gazetteer.db"

def printer(string):
    print(string)
    
def get_sql_values(list_features):
    id_list = list_features.split("##")
    include_string = "("
    for f_id in id_list:
        include_string+=f_id+","
    include_string= include_string[:-1] + ")"
    return include_string

def export_gazetteer_to_linked_places(query):
  data_obj = { "type" : "FeatureCollection","@context": "https://github.com/bgmartins/historical-gazetteer/linkedplaces-export.jsonld","features": []}
  conn = sqlite3.connect( database )
  if(query=="##"):
      data = conn.execute("SELECT DISTINCT feature_id FROM g_feature").fetchall()
  else:
      id_list=query.split("##")  
      include_string = "("
      for f_id in id_list:
          include_string+=f_id+","
      include_string= include_string[:-1] + ")"
      raw_query = "SELECT DISTINCT feature_id FROM g_feature where feature_id in " + include_string
      data = conn.execute(raw_query).fetchall()
  for feature in data:
    feature_obj = { "@id": "https://github.com/bgmartins/historical-gazetteer/" + os.path.basename(database) + "/" + repr(feature[0]), "type": "Feature", "properties":{},
                   "geometry": { "type": "GeometryCollection", "geometries": [] }, "when": {}, "names": [], "types": [], "relations": [], "links": [], "descriptions": [], "depictions": [] }
    for name in conn.cursor().execute("SELECT name, language_code FROM g_feature_name, l_language WHERE g_feature_name.language_id=l_language.language_id AND feature_id=" + repr(feature[0])):
      toponym = { "toponym": name[0], "lang": name[1], "citation": [], "when": [] }
      feature_obj["names"].append(toponym)    
    for geo in conn.cursor().execute("SELECT west_coordinate, south_coordinate FROM g_location LEFT JOIN g_location_geometry ON g_location.location_id=g_location_geometry.location_id WHERE g_location.feature_id=" + repr(feature[0])):
      wkt = "POINT(" + repr(geo[0]) + " " + repr(geo[1]) + ")"
      geo = { "type": "Point", "coordinates": [geo[0],geo[1]], "geo_wkt": wkt, "when": [], "src": "" }
      feature_obj["geometry"]["geometries"].append(geo)    
    for type_obj in conn.cursor().execute("SELECT classification_id, l_scheme_term.term FROM g_classification, l_scheme_term WHERE l_scheme_term.scheme_term_id=g_classification.classification_term_id AND g_classification.feature_id=" + repr(feature[0])):
      type_info = { "identifier": type_obj[0], "label": type_obj[1], "sourceLabel": type_obj[1], "when": [] }
      feature_obj["types"].append(type_info)
    data_obj["features"].append(feature_obj)
  return data_obj

def create_csv_sql(query):
    if(query=="##"):
        sql = "select * from g_feature natural join g_location natural join g_feature_name natural join g_classification where primary_display=1"
        return sql
    values = get_sql_values(query)
    sql = "select feature_id, name, entry_note from g_feature natural join g_location natural join g_feature_name where feature_id in " + values + " and primary_display=1"
    print(sql)
    return sql

def export_gazetteer_to_shp_file(query):
    conn = sqlite3.connect( database )
    try:
        os.remove("export_file.shp")
        os.remove("export_file.shx")
        os.remove("export_file.dbf")
    except:
        pass
    poly_objs={}
    if(query=="##"):
        geo_list=conn.execute("select feature_id, encoded_geometry from g_location_geometry natural join g_location").fetchall()
    else:
        id_list=query.split("##")  
        include_string = "("
        for f_id in id_list:
            include_string+=f_id+","
        include_string= include_string[:-1] + ")"
        raw_query="select feature_id, encoded_geometry from g_location_geometry natural join g_location where feature_id in " + include_string
        geo_list=conn.execute(raw_query).fetchall()
    for geo_id in geo_list:
        poly_objs[geo_id[0]]=geo_id[1]
    driver = ogr.GetDriverByName('Esri Shapefile')
    ds = driver.CreateDataSource('export_file.shp')
    layer = ds.CreateLayer('', None, ogr.wkbPolygon)
    layer.CreateField(ogr.FieldDefn('id', ogr.OFTInteger))
    defn = layer.GetLayerDefn()
    for key_id in poly_objs.keys():
        print(key_id)
        poly=poly_objs[key_id]
        enc_geo = shapely.wkt.loads(poly)
        feat = ogr.Feature(defn)
        feat.SetField('id', key_id)
        # Make a geometry, from Shapely object
        geom = ogr.CreateGeometryFromWkb(enc_geo.wkb)
        feat.SetGeometry(geom)
        layer.CreateFeature(feat)
    feat = geom = None  # destroy these

    return ds

if __name__ == '__main__':
  export_gazetteer_to_shp_file('1##2##3##4##5##6##7##8')
