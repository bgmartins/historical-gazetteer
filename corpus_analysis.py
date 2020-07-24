import sqlite3
import os

database="gazetteer.db"
if not(os.path.isabs(database)): database = os.path.join(os.path.dirname(__file__),database)
conn = sqlite3.connect( database )
conn.enable_load_extension(True)

features = conn.execute("select feature_id, name from g_feature_name").fetchall()

def inspect_file(filename):
    print("inspecting " + filename)
    text = ""
    with open(filename, encoding="utf8") as f:
        text = f.read()
    for feature in features:
        if feature[1] in text:
            conn.execute("update g_feature set time_period_id=30 where feature_id=?",(feature[0],))
    
inspect_file("decm-data/Corpus/1_RG_Guatemala _Acuna.txt")
inspect_file("decm-data/Corpus/2_RG_Antequera_T1_Acuna.txt")
inspect_file("decm-data/Corpus/3_RG_Antequera_T2_Acuna.txt")
inspect_file("decm-data/Corpus/4_RG_Tlaxcala_T1_Acuna.txt")
inspect_file("decm-data/Corpus/5_RG_Tlaxcala_T2_Acuna.txt")
inspect_file("decm-data/Corpus/6_RG_Mexico_T1_Acuna.txt")
inspect_file("decm-data/Corpus/7_RG_Mexico_T2_Acuna.txt")
inspect_file("decm-data/Corpus/8_RG_Mexico_T3_Acuna.txt")
inspect_file("decm-data/Corpus/9_RG_Michoacan_Acuna.txt")
inspect_file("decm-data/Corpus/10_RG_Nueva Galicia_Acuna.txt")
inspect_file("decm-data/Corpus/11_RGs_Yucatan_T1_DeLaGarza.txt")
inspect_file("decm-data/Corpus/12_RGs_Yucatan_T2_DeLaGarza.txt")
inspect_file("decm-data/Corpus/14_Suma_Visita_Pueblos_DelPasoYTroncoso.txt")

conn.commit()