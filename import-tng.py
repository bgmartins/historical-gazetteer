import xmltodict
import sqlite3

conn = sqlite3.connect("test.sqlite")
c = conn.cursor()

with open("export.xml") as fd:
    obj = xmltodict.parse(fd.read())

for row in obj["resultset"]["row"]:
    for column in row["column"]:
        c.execute("INSERT INTO stocks VALUES '?'", [column["@name"], column["#text"]])
    print "item inserted \n"
