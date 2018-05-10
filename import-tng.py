import xmltodict
import sqlite3
#import defusedexpat

## function to verify if a certain key exists and retrieve the value
def verify_key(root, key):
	if key in root:
		return len(root[key])
	else:
		return "false"

conn = sqlite3.connect("test.sqlite")
c = conn.cursor()

with open("tgn1-extract.xml", encoding='utf-8') as fd: obj = xmltodict.parse(fd.read(), encoding='utf-8', force_list={'Associative_Relationship':True})

#print (obj["Vocabulary"]["Subject"])

for row in obj["Vocabulary"]["Subject"]:
	#print (type(row))
	
	id = row["@Subject_ID"]
	print (id)
	## For Associative Relationaships
	if "Associative_Relationships" in row:
		#print(row)
		for rel in row["Associative_Relationships"]["Associative_Relationship"]:
			print (rel)
			#print (row["Associative_Relationships"])
			#print (rel["Historic_Flag"])
	
	#if "Associative_Relationships" in row:
		#print (row["Associative_Relationships"]["Associative_Relationship"])
		#if "Description" in row:
	#preferred_name = row["Terms"]["Preferred_Term"]
	#latitude = row["Coordinates"]["Latitude"]["Decimal"]
	#longitude = row["Coordinates"]["Longitude"]["Decimal"]
	
	#parent = row["Preferred_Parent"]["Parent_Subject_ID"]
	#parent_relation = row["Preferred_Parent"]["Parent_Subject_ID"]
	
	#Vocabulary/Subject/Coordinates/Bounding/Latitude_Least
	#Vocabulary/Subject/Coordinates/Bounding/Latitude_Most
	#Vocabulary/Subject/Coordinates/Bounding/Longitude_Least
	#Vocabulary/Subject/Coordinates/Bounding/Longitude_Most
	#Vocabulary/Subject/Coordinates/Elevation_Meters
	#Vocabulary/Subject/Coordinates/Elevation_Feet
	
	#for column in row["column"]:
        #c.execute("INSERT INTO table VALUES '(?,?)'", [column["@name"], column["#text"]])
		#print ("item inserted \n")
