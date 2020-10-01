import os
import sqlite3
import shapely.wkt
from osgeo import ogr
import zipfile, shutil

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
      for relation in conn.cursor().execute("SELECT related_name, related_feature_feature_id, related_type_term_id from g_related_feature where feature_id = " + repr(feature[0])):
          relation_type = conn.cursor().execute("select term from l_scheme_term where scheme_term_id = " + repr(relation[2])).fetchone()[0]
          relation_info = {"related_name": relation[0],"related_id": relation[1], "related_type":relation_type}
          feature_obj["relations"].append(relation_info)
      data_obj["features"].append(feature_obj)
  print(data_obj)
  return data_obj

def create_csv_sql(query):
    if(query=="##"):
        sql = "select * from g_feature natural join g_location natural join g_feature_name natural join g_classification where primary_display=1"
        return sql
    values = get_sql_values(query)
    sql = "select main.feature_id, name, term ,west_coordinate,east_coordinate,south_coordinate,north_coordinate , group_concat(name) alternative_names \
            from ((g_feature natural join g_feature_name NATURAL join g_location) as main inner join g_classification gc on main.feature_id=gc.feature_id) \
                inner join l_scheme_term on classification_term_id = scheme_term_id " + \
            "where main.feature_id in " + values +" group by main.feature_id"
    return sql

def export_gazetteer_to_shp_file(query):
    conn = sqlite3.connect( database )
    try:
        os.remove("export_file_polygons.shp")
        os.remove("export_file_polygons.shx")
        os.remove("export_file_polygons.dbf")
        os.remove("export_file_points.shp")
        os.remove("export_file_points.shx")
        os.remove("export_file_points.dbf")
        os.remove("export_shapefile.zip")
    except:
        pass
    feature_objs={}
    if(query=="##"):
        geo_list=conn.execute("select feature_id, name, encoded_geometry from g_location_geometry natural join g_location natural join g_feature_name").fetchall()
    else:
        id_list=query.split("##")  
        include_string = "("
        for f_id in id_list:
            include_string+=f_id+","
        include_string= include_string[:-1] + ")"
        raw_query="select feature_id, name, encoded_geometry from g_location_geometry natural join g_location natural join  g_feature_name where feature_id in " + include_string
        geo_list=conn.execute(raw_query).fetchall()
    for res in geo_list:
        feature_objs[res[0]]=[res[1],res[2]]
    driver = ogr.GetDriverByName('Esri Shapefile')
    ds = driver.CreateDataSource('export_file_polygons.shp')
    polyLayer = ds.CreateLayer('', None, ogr.wkbPolygon)
    polyLayer.CreateField(ogr.FieldDefn('id', ogr.OFTInteger))
    polyLayer.CreateField(ogr.FieldDefn('name', ogr.OFTString))
    polydefn = polyLayer.GetLayerDefn()
    for key_id in feature_objs.keys():
        obj=feature_objs[key_id]
        poly=obj[1]
        name=obj[0]
        enc_geo = shapely.wkt.loads(poly)
        feat = ogr.Feature(polydefn)
        feat.SetField('id', key_id)
        feat.SetField('name', name)
        # Make a geometry, from Shapely object
        geom = ogr.CreateGeometryFromWkb(enc_geo.wkb)
        feat.SetGeometry(geom)
        polyLayer.CreateFeature(feat)
    
    driver = ogr.GetDriverByName('Esri Shapefile')
    ds = driver.CreateDataSource('export_file_points.shp')
    pointLayer = ds.CreateLayer('', None, ogr.wkbPoint)
    pointLayer.CreateField(ogr.FieldDefn('id', ogr.OFTInteger))
    pointLayer.CreateField(ogr.FieldDefn('name', ogr.OFTString))
    pointdefn = pointLayer.GetLayerDefn()
    for key_id in feature_objs.keys():
        obj=feature_objs[key_id]
        poly=obj[1]
        name=obj[0]
        enc_geo = shapely.wkt.loads(poly)
        feat = ogr.Feature(pointdefn)
        feat.SetField('id', key_id)
        feat.SetField('name', name)
        # Make a geometry, from Shapely object
        geom = ogr.CreateGeometryFromWkb(enc_geo.wkb)
        feat.SetGeometry(geom)
        pointLayer.CreateFeature(feat)
    
    
    myzipfile = zipfile.ZipFile("export_shapefile.zip", mode='w',compression=0)
    myzipfile.write("export_file_polygons.dbf")   
    myzipfile.write("export_file_polygons.shx")   
    myzipfile.write("export_file_polygons.shp")   
    myzipfile.write("export_file_points.dbf")   
    myzipfile.write("export_file_points.shx")   
    myzipfile.write("export_file_points.shp")   
    
    myzipfile.close()

    return "export_shapefile.zip"

if __name__ == '__main__':
  export_gazetteer_to_shp_file('1##2##3##4##5##6##7##8')
