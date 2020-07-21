# from qgis.core import *
from osgeo import gdal, osr, ogr
import math
import numpy as np
import os
import sys
import shutil
from pprint import pprint
import sqlite3
import shapefile
from shapely.ops import triangulate, polygonize, cascaded_union
import shapely
import shapely.wkt

conn = sqlite3.connect("../gazetteer.db")
c = conn.cursor()
raw_points=[]

for row in c.execute("SELECT west_coordinate,north_coordinate,south_coordinate,east_coordinate,feature_id from g_location where feature_id IN (SELECT DISTINCT feature_id FROM g_classification WHERE classification_term_id=1202)"):
    aux=[]
    aux.append(row[0])
    aux.append(row[1])
    aux.append(row[2])
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
os.system('gdal_rasterize -tr 0.01 0.01 -burn 255 shape_tester.shp ./rasterPoints')

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

distanceGrid = np.zeros(shape = (width, height))
for row in range(width):
    for col in range(height):
        index = 0
        min = math.sqrt((row - points[0][0]) ** 2 + (col - points[0][1]) ** 2)  #/ points[0][2]
        for i in range(1, (len(points) - 1)):
            weightedDistance = math.sqrt((row - points[i][0]) ** 2 + (col - points[i][1]) ** 2) #/ points[i][2]
            if(weightedDistance < min):
                min = weightedDistance
                index = i
        distanceGrid[row, col] = index
        
print(distanceGrid)

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
#setting no data value
# output.GetRasterBand(1).SetNoDataValue(-999)
# #setting extension of output raster
# top left x, w-e pixel resolution, rotation, top left y, rotation, n-s pixel resolution
# output.SetGeoTransform(geotransform)
# setting spatial reference of output raster

# shutil.copy2('rasterVoronoi.tiff', 'VORONOI_IMAGE.tiff')

#raster to shapefile
srs = osr.SpatialReference()
srs.ImportFromWkt(wkt)
output.SetProjection( srs.ExportToWkt() )
sr_proj=output.GetProjection()
print(sr_proj)
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
for shape in shapes:
    poly = shapely.geometry.Polygon(shape.points)
    # enc_geo = poly.simplify(0.1, preserve_topology=False)
    polygons.append(poly)

poly_union=cascaded_union(polygons) 
print(poly_union)

driver = ogr.GetDriverByName('Esri Shapefile')
ds = driver.CreateDataSource('final_poly.shp')
layer = ds.CreateLayer('', None, ogr.wkbPolygon)
# Add one attribute
layer.CreateField(ogr.FieldDefn('id', ogr.OFTInteger))
defn = layer.GetLayerDefn()
## If there are multiple geometries, put the "for" loop here
# Create a new feature (attribute and geometry)
feat = ogr.Feature(defn)
feat.SetField('id', 123)
# Make a geometry, from Shapely object
geom = ogr.CreateGeometryFromWkb(poly_union.wkb)
feat.SetGeometry(geom)
layer.CreateFeature(feat)
feat = geom = None  # destroy these
# Save and close everything
outlayer = ds = layer = feat = geom = None

print("DONEZO")