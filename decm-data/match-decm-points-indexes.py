#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import ftfy
import geopandas
import pandas as pd
from os import listdir
from os.path import isfile, join, splitext
from pandas import ExcelWriter
from pandas import ExcelFile
from similarity.jarowinkler import JaroWinkler

def read_index(index_path):
    map1 = { }
    data1 = pd.read_excel(index_path, sheet_name='PlaceNames', encoding='utf8')
    for index, row in data1.iterrows():
	    id = str(row['id'])
	    id = re.sub('\\..*', '', id)
	    name = ftfy.fix_text(str(row['name']).strip())
	    if len(name)==0: continue
	    try: ftfy.fix_text(alternative_name = str(row['alt_names']))
	    except: alternative_name = ""
	    if name in map1: map1[name] = map1[name] + [id]
	    else: map1[name] = [id]
	    for name in re.split(" *[;,] *", alternative_name):
		    name = name.strip()
		    if len(name)==0: continue
		    if name in map1: map1[name] = map1[name] + [id]
		    else: map1[name] = [id]
    return map1, data1
   
def read_gis(): 
    map2 = { }
    for shp_path in [f for f in listdir('./decm-points') if isfile(join('./decm-points', f)) and splitext(join('./decm-points', f))[1] == ".shp"]:
        data2 = geopandas.read_file(join('./decm-points', shp_path), encoding='utf8')
        for index, row in data2.iterrows():
            if not( 'Placename' in row ): continue
            id = str(row['My_FID']).strip()
            name = ftfy.fix_text(str(row['Placename']).strip())
            if len(name)==0: continue
            alternative_name = ftfy.fix_text(str(row['Alt_names']) + " , " + str(row['ModernName']))
            if name in map2: map2[name] = map2[name] + [(shp_path,id)]
            else: map2[name] = [(shp_path,id)]
            for name in re.split(" *[;,] *", alternative_name):
                name = name.strip()
                if len(name)==0: continue
                if name in map2: map2[name] = map2[name] + [(shp_path,id)]
                else: map2[name] = [(shp_path,id)]
    return map2, data2

jarowinkler = JaroWinkler()
num_index_places = 0
num_index_places_matched = 0
num_index_places_matched_approx = 0
num_index_places_matched_single = 0
matches = set()
map2, data2 = read_gis()
for index_path in [f for f in listdir('./decm-indexes') if isfile(join('./decm-indexes', f)) and splitext(join('./decm-indexes', f))[1] == ".xlsx"]:
    map1, data1 = read_index(join('./decm-indexes', index_path))
    for name1, ids1 in map1.items():
        print("Matching name", name1, "from", index_path) 
        numMatch = 0
        numMatchApprox = 0
        aux = True
        for name2, ids2 in map2.items():
            if name1.lower() == name2.lower():
                for id1 in ids1:
                    for id2 in ids2:
                        matches.add( (index_path, id1, id2[0], id2[1]) )
                numMatch += 1
                aux = False
        sim_threshold = 0.995
        while aux and sim_threshold >= 0.9:
            aux = True
            for name2, ids2 in map2.items():
                if jarowinkler.similarity(name1.lower()[::-1],name2.lower()[::-1]) > sim_threshold:
                    for id1 in ids1:
                        for id2 in ids2:
                            matches.add( (index_path, id1, id2[0], id2[1]) )
                    numMatchApprox += 1
                    aux = False
            sim_threshold -= 0.005
        num_index_places += 1
        if numMatch > 0 or numMatchApprox > 0: num_index_places_matched += 1
        if numMatch == 0 and numMatchApprox > 0: num_index_places_matched_approx += 1
        if numMatch == 1 or ( numMatch == 0 and numMatchApprox == 1 ): num_index_places_matched_single += 1
        
results = [ ]           
for match in matches:
    gis_data = geopandas.read_file(join('./decm-points', match[2]), encoding='utf8')
    index_data = pd.read_excel(join('./decm-indexes', match[0]), sheet_name='PlaceNames', encoding='utf8')
    index_name = ftfy.fix_text(index_data[index_data['id'] == int(match[1])]['name'].values[0])
    try: index_alternative_names = ftfy.fix_text(index_data[index_data['id'] == int(match[1])]['alt_names'].values[0])
    except: index_alternative_names = ''
    try: gis_alternative_names = ftfy.fix_text(gis_data.ix[int(match[3]) - 1,"Alt_names"])
    except: gis_alternative_names = gis_data.ix[int(match[3]) - 1,"Alt_names"]
    try: gis_name = ftfy.fix_text(gis_data.ix[int(match[3]) - 1,"Placename"])
    except: gis_name = gis_data.ix[int(match[3]) - 1,"Placename"]
    result = {'index': match[0], 
              'id_index': match[1], 
              'index_name': index_name,    
              'index_alternative_names': index_alternative_names, 
              'GIS_file': match[2], 
              'GIS_id': match[3], 
              'coords_lon': gis_data.ix[int(match[3]) - 1,"geometry"].centroid.x,
              'coords_lat': gis_data.ix[int(match[3]) - 1,"geometry"].centroid.y,
              'GIS_placename': gis_name,
              'GIS_modernname': ftfy.fix_text(str(gis_data.ix[int(match[3]) - 1,"ModernName"])),
              'GIS_alternative_names': gis_alternative_names }
    results = results + [ result ]    
writer = pd.ExcelWriter('decm-results-match-points-indexes.xlsx', engine='xlsxwriter')
df = pd.DataFrame(results).to_excel(writer, sheet_name='Sheet1', encoding='utf8')
writer.save()
    
print("Number of places in indexes =", num_index_places)
print("Number of places in indexes that are matched =", num_index_places_matched)
print("Number of places in indexes that are matched exactly =", ( num_index_places_matched - num_index_places_matched_approx) )
print("Number of places in indexes that are matched to multiple alternatives =", ( num_index_places_matched - num_index_places_matched_single) )
print("Number of places in indexes that are unambiguously matched =", num_index_places_matched_single)
