# -*- coding: utf-8 -*-
"""
Created on Tue Feb 18 15:59:12 2020

@author: Bruno Magalhaes
"""

import os
import numpy as np
import json
import sqlite3

base_data = {
        "type" : "FeatureCollection",
        "@context@" : "https://raw.githubusercontent.com/whosonfirst-data/whosonfirst-data/master/data/101/711/873/101711873.geojson",
        "features": []
        }

def export_to_whos_on_first( database ):
    data = base_data
    flag=True
    if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
    conn = sqlite3.connect(database)
    for feature in conn.cursor().execute("SELECT DISTINCT feature_id FROM g_feature WHERE collection_id is NOT NULL"):
        feature_obj = { "@id": "https://github.com/bgmartins/historical-gazetteer/" + os.path.basename(database) + "/" + repr(feature[0]), "type": "Feature", "properties":{},
                   "bbox": [],
                   "geometry": { "coordinates":[],"type":[]}
                   }
        
        for geo in conn.cursor().execute("SELECT west_coordinate, east_coordinate, south_coordinate, north_coordinate FROM g_location LEFT JOIN g_location_geometry ON g_location.location_id=g_location_geometry.location_id WHERE g_location.feature_id=" + repr(feature[0])):
            points = [geo[0],geo[1],geo[2],geo[3]]
            feature_obj["bbox"].append(points)
            
        for shape in conn.cursor().execute("SELECT encoded_geometry FROM g_location LEFT JOIN g_location_geometry ON g_location.location_id=g_location_geometry.location_id WHERE g_location.feature_id=" + repr(feature[0])):
            geo_string=shape[0].replace("(","").replace(")","")
            geo_string=geo_string.split(" ",1)
            geo_type=geo_string[0]
            coordinates_string=geo_string[1].split(",")
            coordinates_int=[]
            
            for position in coordinates_string:
                position=list(filter(None,position.split(" ")))
                coordinates_int.append(list(map(float, position)))
    
            points = []
            feature_obj["geometry"]["coordinates"].append(coordinates_int)
            feature_obj["geometry"]["type"].append(geo_type)
            
        data["features"].append(feature_obj)
    return data

if __name__ == '__main__':
  export_to_whos_on_first('gazetteer.db')