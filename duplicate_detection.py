import itertools
import csv
import sqlite3
import os

conn = sqlite3.connect("../gazetteer.db")
c = conn.cursor()
raw_points=[]

def create_duplicate_input_file():
    try:
        os.remove("duplicate_input.csv")
    except:
        pass
    data = conn.execute("select name,feature_id from g_feature_name where primary_display=1").fetchall()
    with open('duplicate_input.csv',mode='w',newline='') as duplicate_file:
        writer = csv.writer(duplicate_file, delimiter='|', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        for a, b in itertools.combinations(data, 2):
            writer.writerow([a[0],b[0]])    
            
def duplicate_processing():
    print("TODO")
    
create_duplicate_input_file()

conn.close()