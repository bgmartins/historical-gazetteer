# from qgis.core import *
from osgeo import gdal, osr, ogr
import math
import numpy as np
import os
import sys
import sqlite3
import shapefile
conn = sqlite3.connect("../gazetteer.db")
c = conn.cursor()
raw_points=[]

for row in c.execute("SELECT west_coordinate,north_coordinate,south_coordinate,east_coordinate,feature_id from g_location where feature_id IN (SELECT DISTINCT feature_id FROM g_classification WHERE classification_term_id=1202)"):
                     #location_id NOT IN (SELECT DISTINCT location_id FROM g_location_geometry)"):
    aux=[]
    aux.append(row[0])
    aux.append(row[1])
    aux.append(row[2])
    raw_points.append(aux)

w = shapefile.Writer('shape_tester')
w.field('points', 'C')

for point in raw_points:
    w.point(point[0], point[1])
    w.record('point')

w.close()

print(len(raw_points))

sf = shapefile.Reader('shape_tester.shp')

#Get the points vector layer
# pointsVector = QgsVectorLayer(sys.argv, 'points', 'ogr')
#Add the vector layer to the map layer registry
    
# QgsMapLayerRegistry.instance().addMapLayer(pointsVector)
os.system('gdal_rasterize -tr 0.001 0.001 -burn 255 shape_tester.shp ./rasterPoints.tif')
#rasterPoints=QgsRasterLayer('./rasterPoints', 'rasterPoints')
#QgsMapLayerRegistry.instance().addMapLayer(rasterPoints)

dataset = gdal.Open('./rasterPoints.tif')
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
        

geotransform = dataset.GetGeoTransform()
wkt = dataset.GetProjection()

#save the distance grid as an output raster
#output file name ( path to where to save the raster file )
outFileName = './rasterVoronoi.tiff'
#call the driver for the chosen format from GDAL
driver = gdal.GetDriverByName('GTiff')
#Create the file with dimensions of the input raster ( rasterized points )
output = driver.Create(outFileName, height*10, width*10, 1, gdal.GDT_Byte)
#set the Raster transformation of the resulting raster
output.SetGeoTransform(dataset.GetGeoTransform())
#set the projection of the resulting raster
output.SetProjection(dataset.GetProjection())
#insert data to the resulting raster in band 1 from the weighted distance grid
output.GetRasterBand(1).WriteArray(distanceGrid)
#setting no data value
output.GetRasterBand(1).SetNoDataValue(-999)
#setting extension of output raster
# top left x, w-e pixel resolution, rotation, top left y, rotation, n-s pixel resolution
output.SetGeoTransform(geotransform)
# setting spatial reference of output raster
srs = osr.SpatialReference()
srs.ImportFromWkt(wkt)
output.SetProjection( srs.ExportToWkt() )

sr_proj=output.GetProjection()
raster_proj = osr.SpatialReference()
raster_proj.ImportFromWkt(sr_proj)
band = output.GetRasterBand(1) 
bandArray = band.ReadAsArray()
outShapefile = "POLYGON"
driver = ogr.GetDriverByName("ESRI Shapefile")
outDatasource = driver.CreateDataSource(outShapefile+ ".shp")
outLayer = outDatasource.CreateLayer('polygonized', srs=raster_proj)
newField = ogr.FieldDefn(str(1), ogr.OFTInteger)
outLayer.CreateField(newField)

gdal.Polygonize( band, None, outLayer, -1, [], callback=None )
outDatasource.Destroy()
sourceRaster = None


# sf = shapefile.Reader("./POLYGON.shp")
# shapes=sf.shapes()
# for shape in shapes:
#     geo_poly = "POLYGON (("
#     print("|||||||||||||||||||||||||||||||||||||||BBOX||||||||||||||||||||||||||||||||||||")
#     for shape_point in shape.points:
#         geo_poly+=str(shape_point[0]) + " " + str(shape_point[1]) + ","
#     geo_poly = geo_poly[:-1]
#     geo_poly+="))"
#     print(shape.bbox)
#     print(geo_poly)


print("DONEZO")

'''
#Call the raster output file
rasterVoronoi = QgsRasterLayer('./rasterVoronoi.tiff', 'weighted Raster')
#Add it to the map layer registry ( display it on the map)
QgsMapLayerRegistry.instance().addMapLayer(rasterVoronoi)

weightedVoronoiVector = QgsVectorLayer('./WeightedVoronoi.shp', 'weighted voronoi', 'ogr')
#load the vector weighted voronoi diagram
QgsMapLayerRegistry.instance().addMapLayer(weightedVoronoiVector)
# #print "all cells with a weighted value"
'''