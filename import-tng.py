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

with open("tgn1-extract.xml", encoding='utf-8') as fd: obj = xmltodict.parse(fd.read(), encoding='utf-8', force_list={'Associative_Relationship':True, 'AR_Date':True})

#print (obj["Vocabulary"]["Subject"])

for row in obj["Vocabulary"]["Subject"]:
	#print (type(row))
	
	id = row["@Subject_ID"]
	print (id)
	## For Associative Relationaships
	if "Associative_Relationships" in row:
		#print(row)
		for rel in row["Associative_Relationships"]["Associative_Relationship"]:
			historic_flag = verify_key(rel, "Historic_Flag")
			print (historic_flag)
			description = verify_key(rel, "Description")
			print (description)
			if "AR_Date" in rel:
				for ar_date in rel["AR_Date"]:
					#print (ar_date)
					ar_display_date = verify_key(ar_date, "Display_Date")
					print (ar_display_date)
					ar_start_date = verify_key(ar_date, "Start_Date")
					print (ar_start_date)
					ar_end_date = verify_key(ar_date, "End_Date")
					print (ar_end_date)
			relatioship_type = verify_key(rel, "Relationship_Type")
			print (relatioship_type)
			if "Related_Subject_ID" in rel:
				for rel_sub in rel["Related_Subject_ID"]:
					vp_subject_id = verify_key(ar_date, "VP_Subject_ID")
					print (vp_subject_id)
					contrib_subject_id = verify_key(ar_date, "Contrib_Subject_ID")
					print (contrib_subject_id)
	
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
