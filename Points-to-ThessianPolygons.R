###     Climate Zone Mapping    ###
##      Polygon to Points       ##


############################################################################
######       Using a Shapefile to create Points to Polygons           ######
######                      "Voronoi Method"                          ######

# Load necessary libraries
library(sf)
library(dplyr)

# Step 1: Load the point shapefile and California boundary shapefile
points <- st_read("CAClusters/CAClusters.shp")  
california <- st_read("ca_boundary/CA_State.shp")

# Step 2: Reproject points and to the same projected coordinate system to prepare for Voronoi polygons
# UTM Zone 10N for California (EPSG:32610)
points_projected <- st_transform(points, crs = 32610)
ca_projected <- st_transform(california, crs = 32610)

# Step 3: Create Voronoi polygons from the points
voronoi_polygons <- st_voronoi(st_union(points_projected))
voronoi_sf <- st_as_sf(st_collection_extract(voronoi_polygons))

# Step 4: Clip Voronoi polygons to the California boundary
voronoi_clipped <- st_intersection(voronoi_sf, ca_projected)

# Step 5: Join the points' attributes to the Voronoi polygons
voronoi_clipped <- st_join(voronoi_clipped, points_projected, join = st_intersects)

# Step 6: Convert Voronoi polygons to have the same CRS as the points
voronoi_clipped <- st_transform(voronoi_clipped, st_crs(points))

# Step 7: Dissolve polygons based on the FinalClust attribute to create 35 zones
zones <- voronoi_clipped %>%
  group_by(FinalClust) %>%
  summarize(x = st_union(x))

# Create output directory 
output_directory <- "climate_zone_polygons"
output_shapefile <- file.path(output_directory, "climate_zone_polygons.shp")

#check if directory already exists, if it doesnt then create directory
if (!dir.exists(output_directory)) { 
  dir.create(output_directory, recursive = TRUE)
}

# Step 8: Save the polygons as a shapefile
st_write(zones, output_shapefile, append=F)

# Print a message when the process is complete
cat("Shapefile has been created at:", output_shapefile)
