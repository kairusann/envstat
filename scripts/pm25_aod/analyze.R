data <- read.table("data/aod_obs.txt",header=T)

data <- data[data$long>-125,]

library(sp)
# set spatial coordinates to create a Spatial object

coordinates(obs) <- c("lon","lat")
coordinates(aod) <- c("lon","lat")
proj4string(obs) <- CRS("+proj=merc +ellps=WGS84")
proj4string(aod) <- CRS("+proj=merc +ellps=WGS84")


library(rgdal)
# Reprojection to fit autoKrige
# obs_t <- spTransform(obs, CRS=CRS("+proj=merc +ellps=WGS84"))

library(maps)

map("state")
points(obs$lon,obs$lat,pch=16,col="blue")
points(aod$lon,obs$lat,pch=16,col="red")


library(ggplot2)
library(scales)
library(rgdal)

par(mfrow=c(2,1))

qplot(long, lat, color=pm,data=data) + 
  scale_colour_gradient(low="blue", high="red",trans="sqrt") + 
  theme_bw() + borders("state", colour="black") + 
  geom_point(size=5,shape=15)

qplot(long, lat, color=aod, data=data) + 
  scale_colour_gradient(low="blue", high="orange",trans="sqrt") + 
  theme_bw() + borders("state", colour="black") + 
  geom_point(size=5,shape=15)


ggplot(obs,aes(lon,lat)) + geom_tile(aes(x,y), fill = var1.pred,data=dat) + 
  scale_fill_continuous(low = "white", high = muted("blue"),name="value") + 
  borders("state", colour="black") + 
  coord_equal()

ggplot(obs,aes(long,lat)) + geom_polygon(aes(group=group), fill="white") + 
  geom_path(color="white",aes(group=group)) + coord_equal() + 
  geom_tile(aes(x = x1, y = x2, fill = var1.pred), data = dat) + 
  scale_fill_continuous(low = "white", high = muted("orange"), name = "value")

library(caret)

data.train <- train(pm~aod,data=data,method="gamSpline",
                    tuneGrid=expand.grid(df=1:10))

data.gam <- data.train$finalModel

summary(data.gam)

plot(data.gam,se=T,residuals=T,col="red",pch=16,cex=0.6)
plot(data.gam$fitted.values,data.gam$residuals,pch=16,cex=0.6,
     xlab = "Fitted Values", ylab = "Residuals")
abline(h=0, lty=2)
lines(smooth.spline(fitted(data.gam), residuals(data.gam)),col="red")
qplot(data.gam$fitted.values,data.gam$residuals) + geom_smooth() + theme_bw()

data$gam.residuals <- data.gam$residuals

qplot(long, lat, color=abs(gam.residuals), data=data) + 
  scale_colour_gradient(low="blue", high="red") + 
  theme_bw() + borders("state", colour="black") +
  geom_point(size=5,shape=15)

data.lm <- lm(pm~aod,data)
summary(data.lm)
data$lm.residuals <- data.lm$residuals

plot(data.lm$fitted.values,data.lm$residuals,pch=16,cex=0.6,
     xlab = "Fitted Values", ylab = "Residuals")
abline(h=0, lty=2)
lines(smooth.spline(fitted(data.lm), residuals(data.lm)),col="red",lwd=2)

qplot(long, lat, color=gam.residuals, data=data) + 
  scale_colour_gradient(low="blue", high="red") + 
  theme_bw() + borders("state", colour="black") +
  geom_point(size=5,shape=15)

qplot(long, lat, color=abs.d, data=data) + 
  scale_colour_gradient(low="blue", high="red",trans="sqrt") + 
  theme_bw() + borders("state", colour="black") + 
  geom_point(size=5,shape=15)



5038.224 on 343 degrees of freedom
Residual Deviance: 4401.885 on 336 degrees of freedo


