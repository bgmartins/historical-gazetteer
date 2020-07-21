import os
import json
import sqlite3

base_data = {
  "type" : "FeatureCollection",
  "@context": "https://github.com/bgmartins/historical-gazetteer/linkedplaces-export.jsonld",
  "features": []
}

def export_gazetteer_to_linked_places( database ):
  data = base_data
  if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
  conn = sqlite3.connect( database )
  for feature in conn.cursor().execute("SELECT DISTINCT feature_id FROM g_feature"):
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
    data["features"].append(feature_obj)
  return data

if __name__ == '__main__':
  data = export_gazetteer_to_linked_places('gazetteer.db')
  with open('export_lfp_data.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)
