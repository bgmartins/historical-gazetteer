import sqlite3

base_data = {
  "type" : "FeatureCollection",
  "@context": "linkedplaces-export.jsonld",
  "features": []
}

def export_gazetteer_to_linked_places( database ):
  data = base_data
  conn = sqlite3.connect( database )
  c = conn.cursor()
  for feature in c.execute("SELECT feature_id FROM g_feature WHERE collection_id is NULL"):
    feature = { "@id": "http://mygaz.org/places/" + row["feature_id"], "type": "Feature", "properties":{}, "geometries": [], "when": {}, "names": [], "types": [], "relations": [], "links": [], "descriptions": [], "depictions": [] }
    data["features"].append(feature)
  return data

print(export_gazetteer_to_linked_places('gazetteer.db'))