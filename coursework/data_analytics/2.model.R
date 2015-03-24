# Load in data
hkintl <- na.omit(read.csv("hkintl2013.csv"))

# library(circular)
# hkintl$winddir<-circular(hkintl$winddir, type=c("angles"),units=c("degrees"),
#             template=c("geographics"), zero=0, rotation=c("clock"))

# GLM - Logistic Regression
summary(hkintl.glm <- 
          glm(reducedvis~., 
          family="binomial",
          hkintl))$coefficients -> glm.coef

glm.vif <- c(0,car::vif(hkintl.glm))
round(cbind(glm.coef,glm.vif),4)

#              Estimate Std. Error z value Pr(>|z|)  glm.vif
# (Intercept)   72.1199    50.9369  1.4159   0.1568   0.0000
# no2            0.0203     0.0123  1.6454   0.0999   3.5339
# o3            -0.0017     0.0070 -0.2431   0.8079   2.9313
# pm10          -0.0169     0.0210 -0.8073   0.4195  12.9643
# so2           -0.0057     0.0372 -0.1546   0.8772   2.9679
# co             0.0007     0.0009  0.8501   0.3953   1.8436
# pm25           0.1602     0.0308  5.2001   0.0000  11.4843
# pressure      -0.0794     0.0453 -1.7535   0.0795   4.8901
# meantemp      -0.4358     0.6012 -0.7249   0.4685 433.6499
# dewpointtemp   0.2561     0.6107  0.4193   0.6750 613.4036
# relhum         0.1070     0.1344  0.7964   0.4258 143.2906
# cloudpct       0.0017     0.0140  0.1217   0.9032   6.3719
# rainfall      -0.2920     0.1550 -1.8845   0.0595   3.0216
# sunshine       0.0540     0.1343  0.4021   0.6876  17.1095
# radiation     -0.0305     0.0720 -0.4242   0.6714  13.7346
# evaporation    0.1107     0.1283  0.8626   0.3883   2.8289
# winddir       -0.0002     0.0022 -0.0740   0.9410   1.5080
# windspeed     -0.0240     0.0196 -1.2212   0.2220   2.4175

summary(hkintl.glm <- 
          glm(reducedvis~no2+o3+pm10+so2+co+pm25+pressure+meantemp+relhum+cloudpct+rainfall+sunshine+radiation+evaporation+winddir+windspeed, 
              family="binomial",
              hkintl))$coefficients -> glm.coef

glm.vif <- c(0,car::vif(hkintl.glm))
round(cbind(glm.coef,glm.vif),4)

#             Estimate Std. Error z value Pr(>|z|) glm.vif
# (Intercept)  57.3951    45.8360  1.2522   0.2105  0.0000
# no2           0.0182     0.0120  1.5109   0.1308  3.4011
# o3           -0.0034     0.0069 -0.4985   0.6181  2.8902
# pm10         -0.0160     0.0210 -0.7634   0.4452 13.2014 x
# so2          -0.0069     0.0373 -0.1863   0.8522  2.9987
# co            0.0008     0.0009  0.8589   0.3904  1.8524
# pm25          0.1637     0.0313  5.2365   0.0000 11.9439
# pressure     -0.0703     0.0438 -1.6055   0.1084  4.5856
# meantemp     -0.1793     0.0654 -2.7420   0.0061  5.0866
# relhum        0.1613     0.0260  6.1963   0.0000  5.5247
# cloudpct      0.0035     0.0133  0.2648   0.7912  5.8012
# rainfallyes  -0.8080     0.3645 -2.2167   0.0266  2.1495
# sunshine      0.0535     0.1338  0.3996   0.6894 17.1002 
# radiation    -0.0147     0.0694 -0.2118   0.8323 12.9946 x 
# evaporation   0.0748     0.1265  0.5913   0.5544  2.7583
# winddir       0.0000     0.0022  0.0078   0.9937  1.4804
# windspeed    -0.0238     0.0195 -1.2162   0.2239  2.3972

summary(hkintl.glm <- 
          glm(reducedvis~no2+o3+so2+co+pm25+pressure+meantemp+relhum+rainfall+sunshine+evaporation+winddir+windspeed, 
              family="binomial",
              hkintl))$coefficients -> glm.coef
glm.vif <- c(0,car::vif(hkintl.glm))
round(cbind(glm.coef,glm.vif),4)

## All collinear variables are screened out

# Treatment for circular variable

glm.step <- step(glm(reducedvis~.,family="binomial",data=hkintl),k=2) # k=3.84
car::vif(glm.step)

glm.pred <- vector("numeric",nrow(hkintl))
for (i in 1:nrow(hkintl)) {
  hkintl.glm <- glm(glm.step$formula,family="binomial",data=hkintl[-i,])
  glm.pred[i] <- predict(hkintl.glm,newdata=hkintl[i,],type="response")
}
glm.pred<-as.factor(ifelse(glm.pred>0.5,"yes","no"))
glm.acc <- sum(glm.pred==hkintl$reducedvis)/nrow(hkintl)
table(glm.pred,hkintl$reducedvis)

# Regsubset Selection - Not applicable to Logistic Regression
library(leaps)
glm.best <- regsubsets(reducedvis~no2+o3+so2+co+pm25+pressure+meantemp+relhum+rainfall+sunshine+evaporation+winddir+windspeed,hkintl,nvmax=13)

# LOOCV
cv.out <- vector("numeric",13)
for (i in 1:13) {
  form <- as.formula(paste("reducedvis~",names(coef(glm.best,id=i))[2],sep=""))
  glm.cv <- glm(form,family="binomial",hkintl)
  cv.out[i] <- cv.glm(hkintl,glm.cv)$delta[1]
}

kz.out <- vector("numeric",13)
tmp <- vector("numeric",nrow(hkintl))
for (i in 1:13) {
  form <- as.formula(paste("reducedvis~",names(coef(glm.best,id=i))[2],sep=""))
  for (j in 1:nrow(hkintl)) {
    hkintl.fit <- glm(form,family="binomial",hkintl[-j,])
    hkintl.pred <- predict(hkintl.fit,hkintl[j,],type="response")
    tmp[j] <- ifelse(hkintl.pred>0.5,"yes","no")
  }
  kz.out[i] <- sum(tmp==hkintl$reducedvis)/length(tmp)
}

# Principal Component Analysis
hkintl.pca<-prcomp(~.-reducedvis,data=hkintl,center=T,scale=T)
hkintl.pc <- data.frame(reducedvis,hkintl.pca$x)
hkintl.pc.glm <- glm(reducedvis~.,family="binomial",data=hkintl.pc)

# Automated Variable Selection - glmulti
library(glmulti)
glmulti.out <-
  glmulti(reducedvis~.,
          data=hkintl,
          level = 1,               # No interaction considered
          method = "h",            # Exhaustive approach - g: generic
          crit = "aic",            # AIC as criteria
          confsetsize = 1,         # Keep 5 best models
          plotty = F, report = F,  # No plot or interim reports
          fitfunction = "glm",     # glm function
          family = "binomial")     # binomial family for logistic regression

glm.pred <- vector("numeric",nrow(hkintl))
for (i in 1:nrow(hkintl)) {
  hkintl.glm <- glm(glmulti.out@formulas[[1]],family="binomial",data=hkintl[-i,])
  glm.pred[i] <- predict(hkintl.glm,newdata=hkintl[i,],type="response")
}
glm.pred<-as.factor(ifelse(glm.pred>0.5,"yes","no"))
glm.fitted <- as.factor(ifelse(hkintl.glm$fitted.values>0.5,"yes","no"))
glm.acc <- sum(glm.pred==hkintl$reducedvis)/nrow(hkintl)
table(glm.pred,hkintl$reducedvis)

hkintl.glm <- glm(glmulti.out@formulas[[1]],family="binomial",data=hkintl)
summary(hkintl.glm)

# glmulti.cv <- vector("numeric",5)
# for (i in 1:5) {
#    glmulti.cv[i] <- cv.glm(hkintl,glm(glmulti.out@formulas[[i]],"binomial",hkintl))$delta[1]
# }

# GAM - Logistic Regression
library(gam)
gam.out <-
  glmulti(reducedvis~.,
          data=hkintl,
          level = 1,               # No interaction considered
          method = "g",            # Exhaustive approach - g: generic
          crit = "aic",            # AIC as criteria
          confsetsize = 5,         # Keep 5 best models
          plotty = F, report = F,  # No plot or interim reports
          fitfunction = "glm",     # glm function
          family = "binomial")     # binomial family for logistic regression

gam.step <- step.gam(gam(reducedvis~s(no2)+s(o3)+s(pm10)+s(so2)+s(co)+s(pm25)+
                           s(pressure)+s(meantemp)+s(dewpointtemp)+s(relhum)+s(cloudpct)+rainfall+
                           s(sunshine)+s(radiation)+s(evaporation)+winddir+
                           s(windspeed),family="binomial",data=hkintl),
                     scope=gam.scope(hkintl,1))


reducedvis~s(no2)+s(pm25)+s(pressure)+s(meantemp)+s(relhum)+rainfall+s(windspeed)

gam.pred <- vector("numeric",nrow(hkintl))
for (i in 1:nrow(hkintl)){
  hkintl.gam <- gam(gam.step$formula,data=hkintl[-i,],family="binomial")
  gam.pred[i] <- predict(hkintl.gam,hkintl[i,],type="response")
}

hkintl.gam <- gam(gam.step$formula,data=hkintl,family="binomial")
gam.pred <- as.factor(ifelse(gam.pred>0.5,"yes","no"))
gam.fitted <- as.factor(ifelse(hkintl.gam$fitted.values>0.5,"yes","no"))
gam.acc <- sum(gam.pred==hkintl$reducedvis)/nrow(hkintl)

summary(hkintl.gam <- gam(reducedvis~s(no2)+s(pm25)+s(pressure)+s(meantemp)+s(relhum)+rainfall+s(windspeed),family="binomial",data=hkintl))
plot(hkintl.gam)

# Classification Tree
library(tree)
set.seed(7)
tree.pred <- vector("numeric",nrow(hkintl))
for (i in 1:nrow(hkintl)){
  hkintl.tree <- tree(reducedvis~.,hkintl[-i,])
  tree.cv <- cv.tree(hkintl.tree,FUN=prune.misclass)
  hkintl.tree <- prune.misclass(hkintl.tree,best=tree.cv$size[which.min(tree.cv$dev)])
  tree.pred[i] <- predict(hkintl.tree,hkintl[i,],type="class")
}
tree.pred <- as.factor(ifelse(tree.pred==1,"no","yes"))
tree.acc <- sum(tree.pred==hkintl$reducedvis)/nrow(hkintl)
table(tree.pred,hkintl$reducedvis)

hkintl.tree <- tree(reducedvis~.,data=hkintl)
tree.size <- cv.tree(hkintl.tree,FUN = prune.misclass)$size
tree.acc <- vector("numeric",length(tree.size))
tree.pred <- matrix(character(),nrow(hkintl),length(tree.size))
for (i in 1:length(tree.size)-1) {
  for (j in 1:nrow(hkintl)){
    hkintl.tree <- prune.misclass(tree(reducedvis~.,hkintl[-j,]),best=tree.size[i])
    tree.pred[j,i] <- predict(hkintl.tree,hkintl[j,],type="class")
  }
  tree.pred[tree.pred==1]="no"
  tree.pred[tree.pred==2]="yes"
  tree.acc[i] <- sum(tree.pred[,i]==hkintl$reducedvis)/nrow(hkintl)
}

hkintl.tree <- tree(reducedvis~.,hkintl)
tree.cv <- cv.tree(hkintl.tree,FUN=prune.misclass)
hkintl.tree <- prune.misclass(hkintl.tree,best=tree.cv$size[which.max(tree.acc)])
tree.fitted <- predict(hkintl.tree,hkintl,type="class")
table(tree.pred[,which.max(tree.acc)],hkintl$reducedvis)
sum(tree.fitted==hkintl$reducedvis)/nrow(hkintl)

# Random Forest
library(randomForest)
rf.pred <- vector("numeric",nrow(hkintl))
for (i in 1:nrow(hkintl)){
  hkintl.rf <- randomForest(reducedvis~.,hkintl[-i,],mtry=8)
  rf.pred[i] <- predict(hkintl.rf,hkintl[i,],type="class")
}
rf.pred <- as.factor(ifelse(rf.pred==1,"no","yes"))
rf.acc <- sum(rf.pred==hkintl$reducedvis)/nrow(hkintl)
table(rf.pred,hkintl$reducedvis)

hkintl.rf <- randomForest(reducedvis~.,hkintl)
sum(hkintl.rf$predicted==hkintl$reducedvis)/nrow(hkintl)
