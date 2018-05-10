import xmltodict
import sqlite3

## function to verify if a certain key exists and retrieve the value
def verify_key(row, key):
	if key in row:
		return "true"
	else:
		return "false"

conn = sqlite3.connect("test.sqlite")
c = conn.cursor()

with open("tgn1-extract.xml") as fd: obj = xmltodict.parse(fd.read())

#print (obj["Vocabulary"]["Subject"])

for row in obj["Vocabulary"]["Subject"]:
	id = row["@Subject_ID"]
	associative = verify_key(row, "Associative_Relationships")
	print (associative)
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
