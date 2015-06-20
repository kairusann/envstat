library(openair)
aq <- import("aq_2013_hkobs.csv",date.format = "%Y%m%d%H%M%S")
met <- import("daily_metob2.csv",date.format="%m/%d/%Y")

TC <- timeAverage(subset(aq, site %in% "Tung_Chung", select = -site),"day")
hkintl <- merge(TC,met,by = "date")

reducedvis <- hkintl$reducedvis
reducedvis <- as.factor(ifelse(hkintl$reducedvis>0,"yes","no"))
hkintl$reducedvis <- NULL
hkintl <- cbind(reducedvis,hkintl)
hkintl$date <- NULL

windRose(mydata=hkintl,wd="winddir",ws="windspeed",ws.int=10,cols="increment",breaks=4,paddle=F,angle=30,main="Background Wind at Waglan Island in 2012-2013",statistic="prop.count")

winddir <- hkintl$winddir

winddir[hkintl$winddir>15&hkintl$winddir<45] <- "NNE"
winddir[hkintl$winddir>45&hkintl$winddir<75] <- "NEE"
winddir[hkintl$winddir>75&hkintl$winddir<105] <- "E"
winddir[hkintl$winddir>105&hkintl$winddir<135] <- "EES"
winddir[hkintl$winddir>135&hkintl$winddir<165] <- "ESS"
winddir[hkintl$winddir>165&hkintl$winddir<195] <- "S"
winddir[hkintl$winddir>195&hkintl$winddir<225] <- "SSW"
winddir[hkintl$winddir>225&hkintl$winddir<255] <- "SWW"
winddir[hkintl$winddir>255&hkintl$winddir<285] <- "W"
winddir[hkintl$winddir>285&hkintl$winddir<315] <- "WWN"
winddir[hkintl$winddir>315&hkintl$winddir<345] <- "WNN"
winddir[hkintl$winddir>345|hkintl$winddir<15] <- "N"
hkintl$winddir <- as.factor(winddir)


write.csv(hkintl,"hkintl2013.csv")
