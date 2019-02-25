import sqlite3
import json
import urllib.request

url = urllib.request.urlopen("http://n2t.net/ark:/99152/p0d.json")
data = json.loads(url.read().decode())

conn = sqlite3.connect('./gazetteer.db')
cur = conn.cursor()

time_period_name_id = int(cur.execute('SELECT max(time_period_name_id) FROM l_time_period_name').fetchone()[0]) + 1
time_period_id = int(cur.execute('SELECT max(time_period_id) FROM g_time_period').fetchone()[0]) + 1

for c in data["periodCollections"]:
    definitions = data["periodCollections"][c]["definitions"]
    source = data["periodCollections"][c]["source"]
    for cd in definitions:
        id = definitions[cd]["id"]
        if "spatialCoverage" in definitions[cd]: spatialCoverage = " - ".join( [aux["label"] for aux in definitions[cd]["spatialCoverage"]] )
        else: spatialCoverage = ""
        type = definitions[cd]["type"]
        start = definitions[cd]["start"]
        if "spatialCoverageDescription" in definitions[cd]: spatialCoverageDescription = definitions[cd]["spatialCoverageDescription"]
        else: spatialCoverageDescription = ""
        label = definitions[cd]["label"].replace("'","`")
        language = definitions[cd]["language"]
        stop = definitions[cd]["stop"]
        localizedLabels = definitions[cd]["localizedLabels"]
        if "in" in start and "year" in start["in"]: start = start["in"]["year"]
        elif "in" in start and "earliestYear" in start["in"]: start = str(int((int(start["in"]["earliestYear"]) + int(start["in"]["latestYear"])) / 2.0))
        else: start=start["label"]
        if "in" in stop and "year" in stop["in"]: stop = stop["in"]["year"]
        elif "in" in stop and "earliestYear" in stop["in"]: stop = str(int((int(stop["in"]["earliestYear"]) + int(stop["in"]["latestYear"])) / 2.0))
        else: stop=stop["label"]
        if "eng-latn" in localizedLabels: localizedLabels = " - ".join(localizedLabels["eng-latn"])                
        id = "http://n2t.net/ark:/99152/" + id
        try: 
            if start == "present": start = "9999-99-99"
            else: start = str(int(start)) + "-01-01"
            if stop == "present": stop = "9999-99-99"
            else: stop = str(int(stop)) + "-12-31"
        except : 
            print("*** ERROR CONVERTING ONE OF THE TEMPORAL PERIODS ***")
            print(id)
            print(label)
            print(start)
            print(stop)
            continue
        cur.execute("INSERT INTO l_time_period_name VALUES (" + str(time_period_name_id) + ",'" + label + "',4,' " + id + " ')")
        cur.execute("INSERT INTO g_time_date_range VALUES (" + str(time_period_name_id) + ",'" + start + "','" + stop + "','" + label + "',5)")
        cur.execute("INSERT INTO g_time_period VALUES (" + str(time_period_id) + ",1279)")
        cur.execute("INSERT INTO g_time_period_to_period_name VALUES (" + str(time_period_id) + "," + str(time_period_name_id) + ")")
        time_period_name_id = time_period_name_id + 1
        time_period_id = time_period_id + 1                
#        TODO: add spatial coverage information
#        print(spatialCoverage)
#        print(spatialCoverageDescription)
#        TODO: add provenance information
#        print(source)
conn.commit()