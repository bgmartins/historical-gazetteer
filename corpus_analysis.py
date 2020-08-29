import sqlite3
import os
import pandas as pd

database="gazetteer.db"
if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
conn = sqlite3.connect( database )
conn.enable_load_extension(True)

features = conn.execute("select feature_id, name from g_feature_name").fetchall()

def get_identifier(table_name, column_name):
    res = conn.execute("SELECT CASE WHEN MAX(" + column_name + ") = COUNT(*) THEN MAX(" + column_name + ") + 1 WHEN MIN(" + column_name + ") > 1 THEN 1 WHEN MAX(" + column_name + ") <> COUNT(*) THEN (SELECT MIN(" + column_name + ")+1 FROM " + table_name + " WHERE (" + column_name + "+1) NOT IN (SELECT " + column_name + " FROM " + table_name + ")) ELSE 1 END FROM " + table_name)
    return res.fetchone()[0]    

def inspect_file(filename):
    df=pd.read_excel(filename)
    place_list = []
    
    print("reading " + filename)
    
    for row in range(df["Topónimo"].size):
        placename=df["Topónimo"][row]
        reference=df["Referencias"][row]
        pages=df["Páginas"][row]
        if(not any(x["placename"] == placename for x in place_list)):
            f_id = conn.execute("select feature_id, feature_name_id from g_feature_name where name = ? and primary_display=1", (placename,)).fetchall()
            if(len(f_id)>0):
                place_obj={
                    "id": f_id,
                    "placename": placename,
                    "reference": reference,
                    "pages": str(pages)
                    }
                place_list.append(place_obj)
        else:
            for pos in range(len(place_list)):
                if(place_list[pos]["placename"]==placename):
                    place_list[pos]["pages"] += ", " + str(pages)
   
    print("db operations.......")    
         
    for place_obj in place_list:
        id_list = place_obj["id"]
        id_include_string = "("
        name_include_string="("
        for f_id in id_list:
            id_include_string+=str(f_id[0])+","
            name_include_string+=str(f_id[1])+","
        id_include_string= id_include_string[:-1] + ")"
        name_include_string= name_include_string[:-1] + ")"
        update_query = "update g_feature set time_period_id=30 where feature_id in " + id_include_string
        conn.execute(update_query)
        
        source_id = get_identifier("g_source","source_id")
        source_reference_id = get_identifier("l_source_reference","source_reference_id")
        entry_source_id = get_identifier("g_entry_source","entry_source_id")
        conn.execute("INSERT INTO l_source_reference ( source_reference_id, citation, reference_author_id ) VALUES (?,?,1)", (source_reference_id, place_obj["reference"]) )
        conn.execute("INSERT INTO g_source ( source_id, source_mnemonic, contributor_id, source_reference_id ) VALUES (?,?,2,?)", (source_id, place_obj["reference"], source_reference_id) )
        conn.execute("INSERT INTO g_entry_source ( entry_source_id, source_id, entry_date ) VALUES (?,?,'now')", (entry_source_id,source_id) )
        
        update_query = "update g_name_to_link_info_reference set source_reference_id = '"+ str(source_reference_id) +"', pages = '"+ place_obj["pages"] +"' where feature_name_id in " + name_include_string
        conn.execute(update_query)
    
        
            
def show_excel_info(filename):  
    file=pd.ExcelFile(filename)
    df = pd.read_excel(filename)
    print(df.keys())
        

inspect_file("./decm-data/Indexes/Índice_Topónimos_Antequera_Tomo_1.xls")
inspect_file("./decm-data/Indexes/Índice_Topónimos_Antequera_Tomo_2.xls")
inspect_file("./decm-data/Indexes/Índice_Toponimos_Guatemala.xls")
inspect_file("./decm-data/Indexes/Índice_Topónimos_Mexico_1.xls")
inspect_file("./decm-data/Indexes/Índice_Topónimos_Mexico_2.xls")
inspect_file("./decm-data/Indexes/Índice_Topónimos_Mexico_3.xls")
inspect_file("./decm-data/Indexes/Índice_Topónimos_Michoacan.xls")
inspect_file("./decm-data/Indexes/Índice_Topónimos_Nueva_Galicia.xls")
inspect_file("./decm-data/Indexes/Índice_Toponimos_Tlaxcala_tomo_1.xls")
inspect_file("./decm-data/Indexes/Índice_Toponimos_Tlaxcala_tomo_2.xls")
inspect_file("./decm-data/Indexes/Índice_Topónimos_Yucatán_tomo_1.xls")
inspect_file("./decm-data/Indexes/Índice_Topónimos_Yucatán_tomo_2.xls")




conn.commit()