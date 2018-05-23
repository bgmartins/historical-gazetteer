import os
import sqlite3
import py_stringmatching as sm
import xmltodict
import datetime
#import defusedexpat

## initial parameters and global variables
new_collection = "no"
collection_name = "TGN"
collection_id = ""

"""
'fluvial island': 'fluvial features',
'unincorporated area': 'recreation areas',
'abbey': 'cableways',
'tourist center': 'training centers',
'inca center': 'atomic centers',
'legislative center': 'legation buildings',
'ducal residence': 'dunes',
'publishing center': 'public use areas',
'overseas territory': 'overpasses',
'urban center': 'urban areas',
'manufacturing center': 'maneuver areas',
'presidio': 'piers',
'national district': 'national capitals',
'geological formation': 'geological features',
'lava flow': 'lava fields',
'diocese': 'ditches',
'quarrying center': 'quarries',
'official residence': 'offices',
'point': 'points (physiographic)',
'funerary building': 'library buildings',
'passage': 'passes',
'financial center': 'facility centers',
'neighborhood': 'neighborhood centers',
'treaty port': 'treatment plants',
'controlled region': 'control points',
'autonomous republic': 'auditoriums',
'fief': 'fields',
'empire': 'mires',
'lost settlement': 'lost rivers',
'textile center': 'tectonic features',
'highland': 'highways',
'monarchy': 'monasteries',
'artists&#39; colony': 'artificial islands',
'river port': 'rivers',
'oligarchy': 'olive groves',
'battlefield park': 'battlefields',
'frontier': 'promontories',
'kibbutz': 'tributaries',
'iron age center': 'iron mines',
'intermittent watercourse': 'intermittent lakes',
'cow town': 'commons',
'river mouth(s)': 'rivers',
'colonial settlement': 'cols',
'city': 'city halls',
'ceremonial mound': 'cerros',
'former body of water': 'sounds (bodies of water)',
'concentration camp': 'concession areas',
'inhabited region': 'indian reservations',
'organization': 'navigation canals',
'river settlement': 'rivers',
'autonomous area': 'auditoriums',
'episcopal see': 'shoals',
'natural arch': 'natural areas',
'voivodship': 'woods',
'agricultural land': 'agricultural colonies',
'viniculture center': 'visitor centers',
'natural pillar': 'natural areas',
'gallo-roman center': 'galleries',
'provincial capital': 'provincial parks',
'frontier settlement': 'fitness centers',
'oppidum': 'open pit mines',
'possession': 'passes',
'suzerainty': 'straits',
'archiepiscopal see': 'archeological sites',
'metallurgical center': 'metropolitan areas',
'country': 'country clubs',
'landgraviate': 'land grants',
'commandery': 'communes',
'arrondissement': 'arroyos',
'alliance': 'palaces',
'general region': 'generation sites',
'city-state': 'city halls',
'earldom': 'beaver dams',
'livestock center': 'fitness centers',
'local region': 'locales',
'gold town': 'gold mines',
'viceroyalty': 'vineyards',
'fortress': 'forests',
'archdiocese': 'archives',
'occupied territory': 'ocean currents',
'vassal state': 'pastoral sites',
'national division': 'nations',
'league': 'ledges',
'facet': 'factories',
'subregional capital': 'sugar plantations',
'former administrative division': 'fourth-order administrative divisions',
'bailiwick': 'bailing stations',
'noble residence': 'neighborhood centers',
'boomtown': 'bottomlands',
'fortified settlement': 'forts',
'overseas department': 'overpasses',
'duchy': 'ditches',
'bulwark': 'barracks',
'federation': 'free trade zones',
'cloister': 'cisterns',
'caliphate': 'capitals',
'papal residence': 'residences',
'dominion': 'docking basins',
'garden suburb': 'gardens',
'island nation': 'island arcs',
'association': 'radio stations',
'pool': 'potholes',
'former nation/state/empire': 'forts',
'trust territory': 'transportation features',
'constitutional monarchy': 'continental margins',
'craftsman center': 'crater lakes',
'defense installation': 'defiles',
'land bridge': 'land regions',
'grand duchy': 'granges',
'manor': 'mansions',
'overseas province': 'overpasses',
'mining center': 'training centers',
'patriarchal see': 'patrol posts',
'&#60;parts of primary inhabited places&#62;': 'pampas',
'federal territory': 'feedlots',
'buried settlement': 'burial caves',
'pre-columbian center': 'precincts',
'unincorporated territory': 'universities',
'ghost town': 'grottoes',
'rock shelter': 'rock deserts',
'former island': 'forges',
'miscellaneous': 'milestones',
'part of inhabited place': 'parishes',
'annex': 'channels',
'rural community': 'rubber plantations',
'metropolis': 'metropolitan areas',
'countship': 'counties',
'judicial center': 'medical centers',
'fur station': 'fire stations',
'deserted settlement': 'deserts',
'island group': 'island arcs',
'marine sanctuary': 'marine features',
'religious community': 'religious centers',
'ephemeral community': 'escarpments',
'cave dwelling': 'caves',
'kingdom': 'parking lots',
'mandate': 'manmade features',
'satrapy': 'streams',
'sacred site': 'grave sites',
'principality': 'provincial parks',
'confederation': 'conservation areas',
'union territory': 'underground irrigation canals',
'pilgrimage center': 'geographic centers',
'roman center': 'road cuts',
'bronze age center': 'breakwaters',
'run': 'ruins',
'colony': 'cols',
'rione': 'rift zones',
'department': 'depressions',
'national cemetery': 'national forests',
'burial site': 'burial caves',
'regional center': 'regions',
'maya (mayan) center': 'management areas (reserves)',
'enclave': 'anclajes',
'ford': 'fiords',
'unitary authority': 'universities',
'square': 'quarries',
'ceremonial site': 'commercial sites',
'shire': 'shrines',
'railroad camp': 'railroad spurs',
'seasonally inhabited place': 'seas',
'political center': 'political entities',
'weapons production center': 'weather stations',
'necropolis': 'leper colonies',
'inactive mine': 'intertidal zones',
'shipbuilding center': 'shopping centers',
'governorate': 'governed places',
'dictatorship': 'districts',
'margraviate': 'marine terminals',
'hierarchy root': 'hydrographic features',
'stage station': 'ranger stations',
'neolithic center': 'facility centers',
'sestiere': 'shelters',
'timber center': 'training centers',
'dependency': 'dependent political entities',
'sporting center': 'shopping centers',
'hacienda': 'habitats',
'primary political unit': 'primitive areas',
'disputed territory': 'districts',
'stream channel': 'stream banks',
'inhabited place': 'industrial areas',
'special city': 'space centers',
'area': 'arenas',
'monastic center': 'atomic centers',
'border (boundary)': 'border posts',
'romano-british center': 'rehabilitation centers',
'khanate': 'headwaters',
'petroleum refining center': 'petroleum fields',
'spa center': 'space centers',
'cultural center': 'cultivated croplands',
'priory': 'prisons',
'lordship': 'lodges',
'medieval center': 'medical centers',
'civitas': 'civil areas',
'stream distributory': 'streams',
'mountain system': 'mountain crests',
'burial chamber': 'burial caves',
'imperial city': 'commercial sites',
"""

def build_type_dictionary( target_scheme_code=12 , type_exceptions={} ):
    type_exceptions = { 
        'agricultural center': 'agricultural facilities',
        'regional capital': 'capitals',
        'entertainment center': 'recreational facilities',
        'fishing spot': 'fishing areas',
        'fishing community': 'fishing areas',
        'inland port': 'ports',
        'department capital': 'capitals',
        'coastal settlement' : 'settlements',
        'agricultural center': 'agricultural facilities' }
    typedictionary = {}
    auxtypes = []
    for line in open('tgn1-extract.xml'):
        line = line.split("<Place_Type_ID>")
        if len(line) <= 1 : continue
        for i in range(1,len(line)):
            name = line[i].split("</Place_Type_ID>")[0]
            typedictionary[name] = name.split("/")[0].strip().lower()
    conn = sqlite3.connect('./gazetteer.db')
    c = conn.cursor()
    for row in c.execute('SELECT * FROM l_scheme_term WHERE scheme_id=' + str(target_scheme_code)): auxtypes.append( (row[0],row[2]) )
    metric = sm.similarity_measure.jaro_winkler.JaroWinkler()
    for tk in typedictionary.keys():
        type1 = tk.split("/")[1].strip().lower()
        if tk in type_exceptions: type1 = type_exceptions[type1]
        max = 0
        match = ()
        for type2 in auxtypes:
            sim = metric.get_sim_score(type1, type2[1].lower())
            if sim > max : 
                max = sim
                match = type2
        typedictionary[tk] = match[0]
    return typedictionary


## function to verify if a certain key exists and retrieve the value
def verify_key(root, key):
    if key in root:
        return root[key]
    else:
        return ""

def get_latest_id(table, id_field):
    c.execute("select {fld} from {tbl} order by {fld} desc limit 1;".format(tbl=table,fld=id_field))
    ## If the table has no records yet, the value 0 is returned
    if c.fetchone() != None:
        return c.fetchone()[0]
    else:
        return 0

conn = sqlite3.connect("test.sqlite3")
c = conn.cursor()

"""
Getting the classification terms dictionary
"""
dict_classification_terms = build_type_dictionary() ## Still not working


"""
We start by creating a collection to use as the source of features
"""
## inserting a new collection and getting its id
if new_collection == "yes":
    new_collection_id = get_latest_id("g_collection", "collection_id")+1
    collection_id = new_collection_id
    #print (new_collection_id)
    c.execute("INSERT INTO {tbl} (collection_id, name, note) VALUES (:col_id , :nm, :nt);".format(tbl = "g_collection"), {'col_id': new_collection_id, 'nm': collection_name , 'nt': '\"collection of features from TGN\"'})
    conn.commit()
    print("collection " + collection_name + " added")
elif new_collection == "no":
    c.execute("SELECT collection_id from g_collection where name ==:nm",{'nm':collection_name})
    collection_id = (c.fetchone()[0])


### Now we open the XML file to import to the gazeteer database
with open("tgn1-extract.xml", encoding='utf-8') as fd: obj = xmltodict.parse(fd.read(), encoding='utf-8', force_list={'Associative_Relationship':True, 'AR_Date':True, 'Coordinates':True})

#print (obj["Vocabulary"]["Subject"])

## This for cycle iterates through all the subjects(features) from the XML file and adds them to the database
for row in obj["Vocabulary"]["Subject"]:

    feature_id = row["@Subject_ID"] #id of the subject
    print (feature_id)
    #print (row)
    
    if row["Descriptive_Note"] != None:
        if row["Descriptive_Note"]["Note_Text"]:
            descriptive_note_text = row["Descriptive_Note"]["Note_Text"]
    else:
        descriptive_note_text = ""
    #print(type(row))
    #print (row(["Descriptive_Note"]["Note_Text"]))
    entry_date = datetime.datetime.now()
    
    """
    Adding a new feature to the database
    """
#    c.execute("INSERT INTO {tbl} \
#             (feature_id, collection_id, is_complete, time_period_id, entry_note, entry_date, modification_date) \
#              VALUES (:fid,:colid,0,1,:entnote,:entdate,:entdate)".format(tbl = "g_feature"),\
#             {'fid':feature_id,'colid':collection_id,'entnote':descriptive_note_text,'entdate':entry_date})
    
    """
    filling table g_feature_name
    """
    # We first extract the latest feature_name_id from the table to increment
    latest_g_feature_name_id = get_latest_id("g_feature_name", "feature_name_id") + 1
    
    # We also need to get the Noun, which is the preferred term inside terms
    if row["Terms"]["Preferred_Term"]["Term_Type"] == "Noun":
        feature_name = row["Terms"]["Preferred_Term"]["Term_Text"]
    else:
        feature_name = ""

#    c.execute("INSERT INTO {tbl} \
#             (feature_name_id, feature_id, primary_display, name, etymology, language_id, transliteration_scheme_id, confidence_note) \
#              VALUES (:fnameid,:fid,1,:fname,"",129,9,"")".format(tbl = "g_feature_name"),\
#             {'fnameid':latest_g_feature_name_id,'fid':feature_id,'fname':feature_name})
    
    """
    filling table g_classification
    """
    # We first get the latest classification id
    latest_g_classification_id = get_latest_id("g_classification","classification_id") + 1
    
    # We then map the place_type to the correct classification_term
    place_type = row["Place_Types"]["Preferred_Place_Type"]["Place_Type_ID"]
    adl_place_type_id = dict_classification_terms[place_type]
    
    c.execute("INSERT INTO {tbl} \
             (classification_id, feature_id, classification_term_id, primary_display, time_period_id,time_period_note) \
              VALUES (:classidid,:fid,:classtermid,1,1,"")".format(tbl = "g_classification"),\
             {'classid':latest_g_classification_id,'fid':feature_id,'classtermid':adl_place_type_id})
    
    
    
    
    
###
## To extract Associative Relationaships if they exist
    if "Associative_Relationships" in row:
        #print(row)
        for rel in row["Associative_Relationships"]["Associative_Relationship"]:
            historic_flag = verify_key(rel, "Historic_Flag")
            #print (historic_flag)
            description = verify_key(rel, "Description")
            #print (description)
            if "AR_Date" in rel:
                for ar_date in rel["AR_Date"]:
                    #print (ar_date)
                    ar_display_date = verify_key(ar_date, "Display_Date")
                    #print (ar_display_date)
                    ar_start_date = verify_key(ar_date, "Start_Date")
                    #print (ar_start_date)
                    ar_end_date = verify_key(ar_date, "End_Date")
                    #print (ar_end_date)
            relatioship_type = verify_key(rel, "Relationship_Type")
            #print (relatioship_type)
            if "Related_Subject_ID" in rel:
                for rel_sub in rel["Related_Subject_ID"]:
                    vp_subject_id = verify_key(ar_date, "VP_Subject_ID")
                    #print (vp_subject_id)
                    contrib_subject_id = verify_key(ar_date, "Contrib_Subject_ID")
                    #print (contrib_subject_id)

## To extract Coordinates if they exist

## The structure is as follows

## Coordinates/Standard/Latitude/Decimal                       mapped to	g_location	north_coordinate + south_coordinate
## Coordinates/Standard/Longitude/Decimal                      mapped to	g_location	east_coordinate + west_coordinate
## Coordinates/Bounding/Latitude/Latitude_Least/Decimal        mapped to	g_location	south_coordinate
## Coordinates/Bounding/Latitude/Latitude_Most/Decimal         mapped to	g_location	north_coordinate
## Coordinates/Bounding/Longitude/Longitude_Least/Decimal      mapped to	g_location	west_coordinate
## Coordinates/Bounding/Longitude/Longitude_Most/Decimal       mapped to	g_location	east_coordinate
## Coordinates/Elevation_Meters                                mapped to	NONE


    if "Coordinates" in row:
        for coor in row["Coordinates"]:
            if "Standard" in coor:
                coor_standard_latitude_decimal = verify_key(coor["Standard"]["Latitude"], "Decimal")
                #print (coor_standard_latitude_decimal)
                coor_standard_longitude_decimal = verify_key(coor["Standard"]["Longitude"], "Decimal")
                #print (coor_standard_longitude_decimal)
            if "Bounding" in coor:
                coor_bounding_latitude_least = verify_key(coor["Bounding"]["Latitude"]["Least"], "Decimal")
                #print (coor_bounding_latitude_least)
                coor_bounding_latitude_most = verify_key(coor["Bounding"]["Latitude"]["Most"], "Decimal")
                #print (coor_bounding_latitude_most)
                coor_bounding_longitude_least = verify_key(coor["Bounding"]["Longitude"]["Least"], "Decimal")
                #print (coor_bounding_longitude_least)
                coor_bounding_longitude_most = verify_key(coor["Bounding"]["Longitude"]["Most"], "Decimal")
                #print (coor_bounding_longitude_most)
            coor_elevation_meters = verify_key(coor, "Elevation_Meters")
            #print (coor_elevation_meters)


###
##To extract Descriptive Notes if they exist

##The structure is as follows

##Descriptive_Note/Note_Text
##Descriptive_Note/Note_Contributors/Note_Contributors/Note_Contributor/Contributor_id
##Descriptive_Note/Note_Sources/Note_Source/Source/Source_ID
##Descriptive_Note/Note_Sources/Note_Source/Source/Brief_Citation
##Descriptive_Note/Note_Sources/Note_Source/Source/Full_Citation
##Descriptive_Note/Note_Sources/Note_Source/Source/Biblio_Note
##Descriptive_Note/Note_Sources/Note_Source/Source/Merged_Status
##Descriptive_Note/Note_Sources/Note_Source/Page


###
##To extract Parent Relationships if they exist

##The structure is as follows

##Parent_Relationships/Preferred_Parent/Parent_Subject_ID
##Parent_Relationships/Preferred_Parent/Relationship_Type
##Parent_Relationships/Preferred_Parent/Historic_Flag
##Parent_Relationships/Preferred_Parent/Parent_Date
##Parent_Relationships/Non_Preferred_Parent/Parent_Subject_ID
##Parent_Relationships/Non_Preferred_Parent/Relationship_Type
##Parent_Relationships/Non_Preferred_Parent/Historic_Flag
##Parent_Relationships/Non_Preferred_Parent/Parent_Date


###
##To extract Place Types if they exist

##The structure is as follows

##Place_Types/Preferred_Place_Type/Place_Type_ID
##Place_Types/Preferred_Place_Type/Display_Order
##Place_Types/Preferred_Place_Type/Historic_Flag
##Place_Types/Preferred_Place_Type/PT_Date
##Place_Types/Non_Preferred_Place_Type/Place_Type_ID
##Place_Types/Non_Preferred_Place_Type/Display_Order
##Place_Types/Non_Preferred_Place_Type/Historic_Flag
##Place_Types/Non_Preferred_Place_Type/PT_Date
##




## Let's now insert the features extracted from the XML into the database



##  inserting a new feature using the collection_id as FK and getting the feature_id to use afterwards
    #c.execute("INSERT INTO table g_feature (collection_id) VALUES (", g_collection_id, '"')
    #feature_id = c.execute("select feature_id from g_feature order by feature_id desc limit 1")


