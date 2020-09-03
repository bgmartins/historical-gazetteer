from osgeo import gdal, osr, ogr
import math
import numpy as np
import os
import sys
import shutil
from pprint import pprint
import json
import sqlite3
import shapefile
from shapely.ops import triangulate, polygonize, cascaded_union
import shapely
import shapely.wkt
import geopandas

conn = sqlite3.connect("../gazetteer.db")
c = conn.cursor()
raw_points=[]

data = geopandas.read_file("./gpw_v4_admin_unit_center_points_population_estimates_rev11_mex.shp", encoding='utf8')

for row in c.execute("SELECT west_coordinate,east_coordinate,south_coordinate,north_coordinate,feature_id from g_location where feature_id in (1,2,3,4,5,6,7,8,9)"):
    aux=[]
    long=(row[0]+row[1])/2
    lat=(row[2]+row[3])/2
    weight=1
    holder_distance=1000
    print("getting weight...")
    for index, row in data.iterrows():
        # print(row["UN_2020_E"])
        # print(row["UN_2020_DS"])
        distance=math.sqrt((row["CENTROID_X"] - long) ** 2 + (row["CENTROID_X"] - lat) ** 2)
        if(distance<holder_distance):
            holder_distance=distance
            print("closer found")
    
    aux.append(long)
    aux.append(lat)
    aux.append(weight)
    raw_points.append(aux)

w = shapefile.Writer('shape_tester')
w.field('points', 'A')

for point in raw_points:
    w.point(point[0], point[1])
    w.record('point')

w.close()

print(len(raw_points))

sf = shapefile.Reader('shape_tester.shp')

#Add the vector layer to the map layer registry
os.system('gdal_rasterize -tr 0.005 0.005 -burn 255 shape_tester.shp ./rasterPoints')

dataset = gdal.Open('./rasterPoints')
numpy_array = dataset.ReadAsArray()
width, height = numpy_array.shape
points = []


#get all the weighted points from the raster
print("get the points with their weights from raster")
for row in range(width):
    for col in range(height):
        if(numpy_array[row,col] != 0):
            points.append([row, col, numpy_array[row,col]])

print("compute the weighted distance grid for each point")

#ocurrencia no corpus para pesos

distanceGrid = np.zeros(shape = (width, height))
for row in range(width):
    for col in range(height):
        index = 0
        min = math.sqrt((row - points[0][0]) ** 2 + (col - points[0][1]) ** 2)  / points[0][2]
        for i in range(1, (len(points) - 1)):
            weightedDistance = math.sqrt((row - points[i][0]) ** 2 + (col - points[i][1]) ** 2) / points[i][2]
            if(weightedDistance < min):
                min = weightedDistance
                index = i
        distanceGrid[row, col] = index
        

geotransform = dataset.GetGeoTransform()
wkt = dataset.GetProjection()

#save the distance grid as an output raster
#output file name ( path to where to save the raster file )
outFileName = './rasterVoronoi.tiff'
#call the driver for the chosen format from GDAL
driver = gdal.GetDriverByName('GTiff')
#Create the file with dimensions of the input raster ( rasterized points )
output = driver.Create(outFileName, height, width, 1, gdal.GDT_Byte)
#set the Raster transformation of the resulting raster
output.SetGeoTransform(dataset.GetGeoTransform())
#set the projection of the resulting raster
output.SetProjection(dataset.GetProjection())

# create color table
colors = gdal.ColorTable()

# set color for each value
colors.SetColorEntry(1, (112, 153, 89))
colors.SetColorEntry(2, (242, 238, 162))
colors.SetColorEntry(3, (242, 206, 133))
colors.SetColorEntry(4, (194, 140, 124))
colors.SetColorEntry(5, (214, 193, 156))
colors.SetColorEntry(6, (20, 113, 156))
colors.SetColorEntry(7, (180, 13, 156))
colors.SetColorEntry(8, (47, 70, 156))
colors.SetColorEntry(9, (145, 123, 156))
colors.SetColorEntry(10, (203, 178, 156))
colors.SetColorEntry(11, (123, 10, 156))
colors.SetColorEntry(12, (89, 35, 156))
colors.SetColorEntry(13, (111, 93, 156))
colors.SetColorEntry(14, (56, 83, 156))
colors.SetColorEntry(15, (160, 150, 156))
colors.SetColorEntry(16, (112, 153, 89))
colors.SetColorEntry(17, (242, 238, 162))
colors.SetColorEntry(18, (242, 206, 133))
colors.SetColorEntry(19, (194, 140, 124))
colors.SetColorEntry(20, (214, 193, 156))
colors.SetColorEntry(21, (20, 113, 156))
colors.SetColorEntry(22, (180, 13, 156))
colors.SetColorEntry(23, (47, 70, 156))
colors.SetColorEntry(24, (145, 123, 156))
colors.SetColorEntry(25, (203, 178, 156))
colors.SetColorEntry(26, (123, 10, 156))
colors.SetColorEntry(27, (89, 35, 156))
colors.SetColorEntry(28, (111, 93, 156))
colors.SetColorEntry(29, (56, 83, 156))
colors.SetColorEntry(30, (160, 150, 156))

output.GetRasterBand(1).SetRasterColorTable(colors)
output.GetRasterBand(1).SetRasterColorInterpretation(gdal.GCI_PaletteIndex)

#insert data to the resulting raster in band 1 from the weighted distance grid
output.GetRasterBand(1).WriteArray(distanceGrid)
output=None

output = gdal.Open('rasterVoronoi.tiff')
#raster to shapefile
srs = osr.SpatialReference()
srs.ImportFromWkt(wkt)
output.SetProjection( srs.ExportToWkt() )
sr_proj=output.GetProjection()
raster_proj = osr.SpatialReference()
raster_proj.ImportFromWkt(sr_proj)
band = output.GetRasterBand(1) 
bandArray = band.ReadAsArray()
outShapefile = "VORONOI"
driver = ogr.GetDriverByName("ESRI Shapefile")
outDatasource = driver.CreateDataSource(outShapefile+ ".shp")
outLayer = outDatasource.CreateLayer('polygonized', srs=raster_proj)
newField = ogr.FieldDefn(str(1), ogr.OFTInteger)
outLayer.CreateField(newField)
gdal.Polygonize( band, None, outLayer, -1, [], callback=None )
outDatasource.Destroy()
sourceRaster = None
#shapefile into union
sf = shapefile.Reader("./VORONOI.shp")
shapes=sf.shapes()

polygons=[]

enc_geo = shapely.wkt.loads("POLYGON ((-97.85597229003906 24.52708244323753, -97.73120117187494 23.77069091796898, -97.89875030517572 22.60180473327659, -97.680419921875 21.66208267211925, -97.14902496337891 20.6118049621582, -96.44736480712885 19.84597206115745, -96.31402587890625 19.31486129760748, -95.74958038330072 18.79513931274425, -95.86208343505854 18.71708488464355, -95.18152618408203 18.70736122131359, -94.49736022949219 18.15041732788109, -93.42013549804682 18.43041610717796, -93.12291717529297 18.34069442749023, -92.34569549560541 18.67097282409691, -91.95708465576166 18.69680595397961, -91.87069702148432 18.57791709899908, -92.00013732910156 18.59930610656738, -92.04513549804676 18.52263832092285, -91.51819610595697 18.44680595397966, -91.22235870361328 18.75152778625488, -91.3629150390625 18.87791633605951, -91.11486053466797 19.01069259643583, -91.09958648681641 19.03124809265159, -91.35680389404297 18.90847206115723, -91.41069793701172 18.83291625976563, -91.40902709960932 18.86902618408209, -91.47235870361317 18.78236389160156, -91.49736022949219 18.7906951904298, -91.38041687011713 18.90069389343273, -90.90152740478516 19.18152809143078, -90.71485900878906 19.36347198486339, -90.70708465576172 19.67569351196312, -90.45319366455078 19.95180511474632, -90.50291442871088 20.49597167968773, -90.31930541992188 21.02263832092308, -88.14125061035151 21.62402725219727, -87.22291564941406 21.41652870178228, -87.08458709716791 21.58958244323753, -86.82597351074219 21.2448616027832, -86.82653045654286 21.41430473327659, -86.7956924438476 21.4065284729005, -86.74041748046864 21.13402748107933, -87.42485809326166 20.22347259521496, -87.47819519042969 20.07819366455078, -87.48180389404286 20.00708389282238, -87.4640274047851 19.99402809143072, -87.46458435058594 19.95597267150879, -87.43680572509766 19.92930603027366, -87.43208312988276 19.90847206115723, -87.42986297607422 19.88791656494163, -87.46958160400385 19.78041648864746, -87.43096923828114 19.88708305358909, -87.46736145019531 19.94486045837402, -87.74013519287104 19.67124938964849, -87.68291473388666 19.49124908447294, -87.45402526855463 19.64819526672386, -87.41014099121094 19.59208297729487, -87.68402862548828 19.31569480896007, -87.65347290039063 19.18041610717785, -87.54624938964838 19.30319213867199, -87.51125335693354 19.25569534301781, -87.48236083984369 19.32430648803711, -87.44541931152344 19.31208419799799, -87.84402465820313 18.19152832031273, -88.07402801513666 18.47958374023449, -87.99764251708973 18.66791725158686, -88.05180358886713 18.86652755737299, -88.28514099121088 18.49458312988304, -88.51808929443359 18.46081733703613, -88.84314727783197 17.86725997924799, -89.02810668945313 18.00440025329601, -89.1468887329101 17.81458663940441, -90.98203277587891 17.81511116027843, -90.99017333984369 17.25935745239269, -91.43796539306641 17.25000953674311, -90.38556671142578 16.40892028808616, -90.42192840576172 16.09981346130388, -91.7252197265625 16.08094978332531, -92.21464538574219 15.26556777954107, -92.05996704101563 15.07166099548351, -92.22624969482422 14.53291702270531, -94.12374877929682 16.22291946411161, -94.44319152832031 16.21541595458979, -93.96930694580078 15.99263858795177, -94.72569274902338 16.21097183227556, -94.58069610595703 16.33652687072765, -94.80180358886713 16.27263832092297, -94.88041687011719 16.43569374084478, -95.06597137451166 16.28041648864746, -94.95236206054688 16.24347305297857, -94.86180877685536 16.28291702270531, -94.8165283203125 16.2734718322755, -94.92763519287109 16.2409725189209, -94.98930358886713 16.24430465698237, -95.07402801513672 16.26597023010282, -95.10514068603516 16.23569488525391, -94.8709716796875 16.23624992370628, -94.76680755615229 16.22374725341808, -94.74764251708979 16.20902633666987, -95.16791534423822 16.19680786132835, -95.43541717529291 15.97569370269775, -96.55764007568359 15.65652847290039, -97.78569793701172 15.98124980926508, -98.77319335937494 16.55458259582514, -99.65208435058588 16.69430541992199, -101.0615310668945 17.26513862609863, -101.9634704589844 17.96791648864769, -103.360969543457 18.2626380920413, -103.9584732055664 18.8712482452392, -104.9384689331055 19.3073616027832, -105.5501403808594 20.09402847290045, -105.6948623657226 20.40958404541021, -105.2451400756836 20.58124732971191, -105.5387496948242 20.76930618286133, -105.2365264892578 21.05930519104015, -105.1881942749022 21.45930671691906, -105.6373596191406 21.97513961791992, -105.6354141235352 22.18263626098627, -105.5254135131835 22.06291770935059, -105.4926376342773 22.0806941986084, -105.492919921875 22.07458305358904, -105.4773635864258 22.05069351196306, -105.4676361083984 22.04402732849115, -105.4684753417968 22.03680610656744, -105.4595870971679 22.02291870117188, -105.4495849609374 22.0265274047851, -105.4701385498047 22.12958335876471, -105.6140289306641 22.21319389343273, -105.6618041992188 22.70791625976585, -105.6984710693359 22.4720859527589, -107.1437530517578 24.14236068725592, -107.2073593139648 24.12097167968761, -107.8045806884765 24.49735832214378, -107.4881973266602 24.3251380920413, -107.5531921386718 24.52180480957054, -108.0009689331055 24.65513610839866, -108.0656967163085 25.08208274841309, -108.7509689331055 25.36458396911621, -108.6204147338867 25.34041595458984, -108.7773590087891 25.54708480834984, -109.0440292358398 25.4634704589846, -109.1198577880859 25.54680633544945, -108.9829177856445 25.54208374023443, -108.9245834350585 25.61902809143078, -108.9379196166992 25.67236137390148, -109.1051406860352 25.57013893127464, -109.2612533569336 25.70097160339367, -109.2662506103516 25.64374923706055, -109.1887512207031 25.62513923645048, -109.1606979370117 25.56097221374523, -109.3948593139648 25.63736152648937, -109.2826385498047 25.71430587768555, -109.3998641967773 25.68097305297852, -109.4365310668945 25.99819374084484, -109.3291702270508 26.09194374084473, -109.3747253417968 26.10139083862327, -109.2891693115234 26.27583312988287, -109.2486114501953 26.31555557250999, -109.3036117553711 26.16861152648943, -109.2894439697265 26.13944435119629, -109.2108306884766 26.34305572509766, -109.1113891601562 26.18611145019548, -109.0911102294922 26.28472137451189, -109.250274658203 26.47444534301781, -109.2483367919921 26.36666870117216, -109.259162902832 26.31916618347168, -109.483055114746 26.7438907623291, -109.8144454956054 26.74555587768566, -109.9716415405273 27.10659027099626, -110.5214462280273 27.28985404968262, -110.6277770996094 27.6241664886474, -110.5177307128906 27.85631179809593, -111.1052780151367 27.93583106994652, -111.4349975585938 28.37138938903814, -111.7109832763672 28.45753288269043, -111.9524993896484 28.75916862487804, -111.8488693237305 28.79649353027344, -112.1717529296874 28.9678573608399, -112.233024597168 29.30744361877453, -112.4111328124999 29.3458747863769, -113.0869445800781 30.68277931213402, -113.0625 31.15972137451172, -113.624168395996 31.32722282409679, -113.9030532836913 31.62416648864769, -114.1697235107422 31.4974994659425, -114.8083343505859 31.81555557250994, -114.8897247314453 31.14472389221214, -114.7102813720703 30.90944480895996, -114.5646209716796 30.01102256774897, -113.6375122070313 29.28367233276396, -113.5254821777343 28.89316558837885, -113.2211074829102 28.8253173828125, -113.1033325195313 28.50527954101563, -112.8458480834961 28.44023323059082, -112.770278930664 27.86027526855474, -111.9529266357422 27.09654235839866, -111.7796936035156 26.5657081604005, -111.6769104003906 26.587621688843, -111.8510208129882 26.87938308715843, -111.5614776611328 26.69750785827642, -111.3059692382813 25.77347183227539, -110.6848602294921 24.88485908508306, -110.6118087768554 24.25680541992188, -110.3543090820312 24.11263847351097, -110.2337493896484 24.34458351135254, -109.4679183959961 23.55513954162598, -109.4593048095703 23.19569587707525, -109.8937530517578 22.87430572509777, -110.0620803833008 22.94930648803734, -110.3365249633789 23.56736373901379, -111.6568069458008 24.56958389282249, -111.8190307617188 24.50958251953148, -111.9268035888672 24.74930572509783, -112.1206970214844 24.78263854980463, -112.0770797729492 24.93347167968761, -112.1015243530273 25.00736236572266, -112.1406936645508 24.81125068664562, -112.1784744262695 24.81930541992205, -112.0245819091796 25.47458267211914, -112.2316665649414 26.08194351196295, -113.067527770996 26.60455894470215, -113.244384765625 26.78668212890636, -113.1389617919921 26.8577766418457, -113.1636962890625 26.99267578125011, -113.2655029296874 26.75207519531273, -113.4578323364258 26.83055686950701, -113.5479125976561 26.71972656250011, -113.5764694213867 26.70526695251465, -113.609375 26.71447753906273, -113.849998474121 26.96888732910173, -114.4343261718749 27.17608642578148, -114.5136718749999 27.41668510437029, -115.0269470214843 27.74083328247082, -115.0557861328125 27.8623046875, -114.5016174316406 27.7727165222168, -114.318374633789 27.87865447998041, -114.1011123657226 27.60361289978027, -113.9572219848632 27.65916442871094, -113.9622192382813 27.7432861328125, -113.9295883178711 27.75242233276379, -113.9588317871093 27.64981842041016, -113.8653182983398 27.54616165161133, -113.898094177246 27.82056045532238, -114.1169433593749 27.70583343505871, -114.1486129760742 27.95222473144543, -114.2736129760742 27.89694213867199, -114.1336059570313 28.08410644531267, -114.1524505615234 28.00671958923351, -114.1113891601563 27.92611122131353, -112.8283081054688 27.94927978515625, -114.0946960449219 27.95287322998047, -114.0449981689453 28.46361160278343, -114.1644897460938 28.64227294921881, -114.9683303833008 29.37555503845215, -115.6986083984374 29.75527763366716, -116.0582962036133 30.79641532897961, -116.3376770019531 30.96887397766136, -116.3616638183594 31.24361038208013, -116.691665649414 31.55361175537132, -116.6163711547852 31.85032081604015, -116.8804016113281 32.01788711547846, -117.1239013671874 32.5308837890625, -114.7192001342773 32.71804046630859, -114.81201171875 32.49432373046898, -111.0728073120117 31.32917022705084, -108.2090530395507 31.33402061462402, -108.2090225219726 31.78452110290527, -106.5290298461913 31.78449058532715, -104.9219512939453 30.60531997680664, -104.5133514404296 29.63545036315929, -103.2857131958008 28.97891044616711, -102.8679428100586 29.2221508026123, -102.671516418457 29.74391937255882, -102.3189010620117 29.8779697418214, -101.4037780761719 29.77082061767601, -100.6797714233398 29.10576057434082, -100.2770233154296 28.25705909729015, -99.51596069335938 27.5669994354248, -99.44525146484369 27.02181053161632, -99.08701324462891 26.40150070190424, -98.19901275634766 26.05367279052763, -97.64662933349604 26.02775192260765, -97.42919921874989 25.84112548828148, -97.14624786376953 25.96597290039063, -97.18264007568354 25.67513847351097, -97.42124938964838 25.23625183105486, -97.5281982421875 25.47541618347191, -97.53514099121088 25.28541755676281, -97.79319763183588 25.29597282409674, -97.65041351318354 24.91902732849121, -97.74180603027338 24.488193511963, -97.85597229003906 24.52708244323753))")
print(enc_geo)
polygons.append(enc_geo)

print("----------------------------------ENC-GEO------------------------------")

for shape in shapes:
    poly = shapely.geometry.Polygon(shape.points)
    enc_geo = poly.simplify(0.05, preserve_topology=True)
    print(enc_geo)
    polygons.append(enc_geo)

# with open("../covered-region.geojson", encoding="utf-8") as geojson:
#     data = json.load(geojson)
#     for feature in data['features']:
#         for poly in feature['geometry']['coordinates']:

poly_union=cascaded_union(polygons)

driver = ogr.GetDriverByName('Esri Shapefile')
ds = driver.CreateDataSource('final_poly.shp')
layer = ds.CreateLayer('', None, ogr.wkbPolygon)
# Add one attribute
layer.CreateField(ogr.FieldDefn('id', ogr.OFTInteger))
defn = layer.GetLayerDefn()
## If there are multiple geometries, put the "for" loop here
# Create a new feature (attribute and geometry)
for poly in polygons:
    feat = ogr.Feature(defn)
    feat.SetField('id', 123)
    # Make a geometry, from Shapely object
    geom = ogr.CreateGeometryFromWkb(poly.wkb)
    feat.SetGeometry(geom)
    layer.CreateFeature(feat)
feat = geom = None  # destroy these
# Save and close everything
output = outlayer = ds = layer = feat = geom = None

print("DONEZO")