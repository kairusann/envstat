## Load the required libraries
library(maptools)
library(sp)
library(maps)
## Load in data for analysis and some housekeeping
setwd("C:/Users/Kyle/Documents/JHU/14Fall/Remote Sensing of the Environment/Term_Project/data")
States<-readShapePoly("C:/Users/Kyle/SkyDrive/Documents/Geospatial analysis/geospatial/Problem 1/States_reproj_lower48_copy-1/States_reproj_lower48.shp")
aod <- read.table("US_AOD2013.txt",skip = 9)
obs <- read.table("US_OBS2013.txt",skip = 1)

## Visualization of satellite data
aod.mat <- matrix(aod$V3,nrow=70)
x <- seq(-129.5,-60.5)
y <- seq(23.5,54.5)
coords_aod <- project(as.matrix(cbind(aod$V2,aod$V1)),"+proj=eqdc +lat_0=39 +lon_0=-96 +lat_1=33 +lat_2=45 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs")
aod.geo<-as.geodata(data.frame(easting=coords_aod[,1],
                                northing=coords_aod[,2],
                                pm25=aod$V3),covar.col=1)

image(x,y,aod.mat,xlab = "Longitude",ylab="Latitude",col=heat.colors(10))
image(x,y,aod.mat,xlab="",ylab="",axes=F,col=heat.colors(10))
map("state",add=TRUE,lwd=1.8)
title("AOD-550nm in United State 2012")
filled.contour(x,y,aod.mat,xlab="Longitude",ylab="Latitude",
               col=terrain.colors(16),axes=F)
map("state",add=TRUE,lwd=1.5)
title("AOD-550nm in United State 2012")

## Now let's deal with the ground observation data!
pm25 <- data.frame(long=obs$V2,lat=obs$V1,obs=obs$V3)
pm25 <- pm25[pm25$long>-125,]
pm25 <- pm25[pm25$lat>20,]

latlong <- as.matrix(cbind(pm25$long,pm25$lat))

# Removed duplicated coordinates
library(geoR)
pm25 <- pm25[-dup.coords(latlong)[2],]
latlong <- as.matrix(cbind(pm25$long,pm25$lat))

# Convert to UTM 
# coords <- project(latlong,"+proj=utm +zone=12 +datum=NAD83 +units=m +no_defs")

# Convert to State Plane
library(rgdal)
coords_sp <- project(latlong,"+proj=eqdc +lat_0=39 +lon_0=-96 +lat_1=33 +lat_2=45 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs")

pm25.geo<-as.geodata(data.frame(easting=coords_sp[,1],
                                 northing=coords_sp[,2],
                                 pm25=pm25$obs),covar.col=1)

plot(States)
points.geodata(pm25.geo,pt.divide="quartiles",cex.min=.8,cex.max=.8,add.to.plot=T,x.leg="bottomleft")

# grid<-expand.grid(V1=seq(-129.5,-60.5), V2=seq(23.5,54.5))

grid<-expand.grid(easting=seq(-2329176-100000,2244937+100000,len=100),
                  northing=seq(-1452329-100000,1365129+100000,len=100))

points(grid,pch=".")

maxdist<-summary(pm25.geo)$distances.summary[2]
pm25.vario1<-variog(pm25.geo,max.dist=maxdist/2)

plot(pm25.vario1,pch=16,xlab="Distance",ylab="Semivariogram",pty="m")
title("PM Semivariogram (retricted < 1/2 max distance)")
eyefit(pm25.vario1)

pm25.vario.wls<-variofit(pm25.vario1,ini.cov.pars=c(13.51,2572714.51),
                         cov.model="exponential",nugget=7.82,weight="cressie")

plot(pm25.vario1,pch=16,xlab="Distance",ylab="Semivariogram",pty="m")
title("Fitted WLS Semivariogram for PM2.5 Levels")
lines(pm25.vario.wls)

OK.pred<-krige.conv(pm25.geo,locations=grid,
                    krige=krige.control(obj.model=pm25.vario.wls))

image(OK.pred,loc=grid,axes=F,xlab="",ylab="")
points(pm25.geo$coords,pch=16,cex=.5)
plot(States,add=TRUE)
