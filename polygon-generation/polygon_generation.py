# from qgis.core import *
from osgeo import gdal, osr
import math
import numpy as np
import os
import sys
import sqlite3
import shapefile

conn = sqlite3.connect("../gazetteer.db")
c = conn.cursor()
raw_points=[]

for row in c.execute("SELECT west_coordinate,north_coordinate from g_location where feature_id IN  \
                     (SELECT DISTINCT feature_id FROM g_classification WHERE classification_term_id=1164) limit 50"):
    aux=[]
    aux.append(row[0])
    aux.append(row[1])
    raw_points.append(aux)

w = shapefile.Writer('shape_tester')
w.field('points', 'C')

for point in raw_points:
    w.point(point[0], point[1])
    w.record('point')

w.close()

sf = shapefile.Reader('shape_tester.shp')
print(sf)

#Get the points vector layer
# pointsVector = QgsVectorLayer(sys.argv, 'points', 'ogr')
#Add the vector layer to the map layer registry
    
# QgsMapLayerRegistry.instance().addMapLayer(pointsVector)
os.system('gdal_rasterize -tr 0.01 0.01 -burn 255 shape_tester.shp ./rasterPoints.tif')
#rasterPoints=QgsRasterLayer('./rasterPoints', 'rasterPoints')
#QgsMapLayerRegistry.instance().addMapLayer(rasterPoints)

dataset = gdal.Open('./rasterPoints.tif')
numpy_array = dataset.ReadAsArray()
width, height = numpy_array.shape
points = []

print(width)
print(height)

#get all the weighted points from the raster
print("get the points with their weights from raster")
for row in range(width):
    for col in range(height):
        if(numpy_array[row,col] != 0):
            points.append([row, col, numpy_array[row,col]])

print("compute the weighted distance grid for each point")

print(points)
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

# #polygonize the result raster
# os.system('gdal_polygonize.py "./rasterVoronoi.tiff" -f "ESRI Shapefile" "./WeightedVoronoi.shp" WeightedVoronoi')

os.system('gdal_polygonize.py rasterVoronoi.tiff -f "ESRI Shapefile" vectorized_result.shp')

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