# -*- coding: utf-8 -*-
"""
Created on Tue Feb 18 15:59:12 2020

@author: Bruno Magalhaes
"""

import os
import numpy as np
import json
import sqlite3
import shapely.wkt

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

def export_to_whos_on_first(database, features,names):
    data = {
        "type" : "FeatureCollection",
        "@context@" : "https://raw.githubusercontent.com/whosonfirst-data/whosonfirst-data/master/data/101/711/873/101711873.geojson",
        "features": []
        }
    flag=True
    if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
    conn = sqlite3.connect(database)
    for feature,name in zip(features,names):
        feature_obj = { "type": "Feature", 
                       "feature_id":int(feature),
                       "properties":{
                           "name": name,
                           "amenity": name,
                           "popupContent": name + " (id: " + str(feature) + ")"},
                       "geometry": { "coordinates":None,"type":None}
                       }
            
        for shape in conn.cursor().execute("select encoded_geometry from g_location_geometry where location_id in (select location_id from g_location where feature_id=?)" , (int(feature),)):
            if(shape[0]==None):
                feature_obj["geometry"]["coordinates"]=None
                feature_obj["geometry"]["type"]=None
            else:
                geo_string=shape[0].replace("(","").replace(")","")
                geo_string=geo_string.split(" ",1)
                geo_type=geo_string[0]
                if geo_type=="MULTIPOLYGON" or geo_type=="POLYGON":
                    P = shapely.wkt.loads(shape[0])
                    MP=shapely.geometry.mapping(P)
                    feature_obj["geometry"]=MP
                else:
                    coordinates_string=geo_string[1].split(",")
                    coordinates_int=[]
                    for position in coordinates_string:
                        position=list(filter(None,position.split(" ")))
                        coordinates_int=[float(position[1]),float(position[0])]
                        # coordinates_int=(list(map(float, position)))
                    feature_obj["geometry"]["coordinates"]=coordinates_int
                    feature_obj["geometry"]["type"]=geo_type.title()
        data["features"].append(feature_obj)
    return data

def path_to_top(base_id,conn):
    related_list = conn.execute("select related_feature_feature_id from g_related_feature where feature_id=? and related_type_term_id=1268 order by related_feature_feature_id DESC",(base_id,)).fetchall()
    return_list=[]
    print(related_list)
    for related in related_list:
        new_list = path_to_top(related[0],conn)
        print(new_list)
        return_list.append(new_list)
    if(return_list==[]):
        return []
    return return_list

def create_hierarchy(database,base_id):
    if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
    conn = sqlite3.connect(database)
    return []

