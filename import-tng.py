import xmltodict
import sqlite3
#import defusedexpat

## function to verify if a certain key exists and retrieve the value
def verify_key(root, key):
	if key in root:
		return root[key]
	else:
		return ""

conn = sqlite3.connect("test.sqlite")
c = conn.cursor()

with open("tgn1-extract.xml", encoding='utf-8') as fd: obj = xmltodict.parse(fd.read(), encoding='utf-8', force_list={'Associative_Relationship':True, 'AR_Date':True, 'Coordinates':True})

#print (obj["Vocabulary"]["Subject"])

for row in obj["Vocabulary"]["Subject"]:
	#print (type(row))
	
	feature = row["@Subject_ID"] #id of the subject
	print (feature)
	
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
					
"""
To extract Coordinates if they exist

The structure is as follows

Coordinates/Standard/Latitude/Decimal						mapped to	g_location	north_coordinate + south_coordinate
Coordinates/Standard/Longitude/Decimal						mapped to	g_location	east_coordinate + west_coordinate
Coordinates/Bounding/Latitude/Latitude_Least/Decimal		mapped to	g_location	south_coordinate
Coordinates/Bounding/Latitude/Latitude_Most/Decimal			mapped to	g_location	north_coordinate
Coordinates/Bounding/Longitude/Longitude_Least/Decimal		mapped to	g_location	west_coordinate
Coordinates/Bounding/Longitude/Longitude_Most/Decimal		mapped to	g_location	east_coordinate
Coordinates/Elevation_Meters								mapped to	NONE
"""

	if "Coordinates" in row:
		for coor in row["Coordinates"]:
			if "Standard" in coo:
				coor_standard_latitude_decimal = verify_key(coor["Standard"]["Latitude"], "Decimal")
				#print (coor_standard_latitude_decimal)
				coor_standard_longitude_decimal = verify_key(coor["Standard"]["Longitude"], "Decimal")
				#print (coor_standard_longitude_decimal)
			if "Bounding" in coo:
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
			
"""
To extract Descriptive Notes if they exist

The structure is as follows

Descriptive_Note/Note_Text
Descriptive_Note/Note_Contributors/Note_Contributors/Note_Contributor/Contributor_id
Descriptive_Note/Note_Sources/Note_Source/Source/Source_ID
Descriptive_Note/Note_Sources/Note_Source/Source/Brief_Citation
Descriptive_Note/Note_Sources/Note_Source/Source/Full_Citation
Descriptive_Note/Note_Sources/Note_Source/Source/Biblio_Note
Descriptive_Note/Note_Sources/Note_Source/Source/Merged_Status
Descriptive_Note/Note_Sources/Note_Source/Page
"""

"""
To extract Parent Relationships if they exist

The structure is as follows

Parent_Relationships/Preferred_Parent/Parent_Subject_ID
Parent_Relationships/Preferred_Parent/Relationship_Type
Parent_Relationships/Preferred_Parent/Historic_Flag
Parent_Relationships/Preferred_Parent/Parent_Date
Parent_Relationships/Non_Preferred_Parent/Parent_Subject_ID
Parent_Relationships/Non_Preferred_Parent/Relationship_Type
Parent_Relationships/Non_Preferred_Parent/Historic_Flag
Parent_Relationships/Non_Preferred_Parent/Parent_Date
"""

"""
To extract Place Types if they exist

The structure is as follows

Place_Types/Preferred_Place_Type/Place_Type_ID
Place_Types/Preferred_Place_Type/Display_Order
Place_Types/Preferred_Place_Type/Historic_Flag
Place_Types/Preferred_Place_Type/PT_Date
Place_Types/Non_Preferred_Place_Type/Place_Type_ID
Place_Types/Non_Preferred_Place_Type/Display_Order
Place_Types/Non_Preferred_Place_Type/Historic_Flag
Place_Types/Non_Preferred_Place_Type/PT_Date
"""


	
"""
Let's now insert the values extracted from the XML into the database
"""
##	inserting a new collection and getting its id
	c.execute("INSERT INTO table g_collection (name) VALUES ('TGN');")
	collection_id = c.execute(" select collection_id from g_collection where name = 'TGN';")

##	inserting a new feature using the collection_id as FK and getting the feature_id to use afterwards
	c.execute("INSERT INTO table g_feature (collection_id) VALUES (", g_collection_id, '"')
	feature_id = c.execute("select feature_id from g_feature order by feature_id desc limit 1")


		#print ("item inserted \n")
