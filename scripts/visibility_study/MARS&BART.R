hkintl <- na.omit(read.csv("hkintl2013.csv"))
set.seed(7)

library(e1071)
svm.pred <- vector("numeric",nrow(hkintl))
for (i in 1:nrow(hkintl)) {
  hkintl.svm <- svm(reducedvis~.,data=hkintl[-i,],kernel="linear",cost=2,scale=T)
  svm.pred[i] <- predict(hkintl.svm,newdata=hkintl[i,])
}
svm.pred <- factor(svm.pred,levels=c(1,2),label=c("no","yes"))
svm.acc <- sum(svm.pred==hkintl$reducedvis)/nrow(hkintl)
table(svm.pred,hkintl$reducedvis)

hkintl.svm <- ksvm(reducedvis~.,data=hkintl,kernel="vanilladot",C=2)
hkintl.svmpath <- svmpath(x=hkintl[,-1],y=hkintl[,1])
sum(hkintl.svm@fitted==hkintl$reducedvis)/nrow(hkintl)

library(earth)
earth.pred <- vector("numeric",nrow(hkintl))
for (i in 1:nrow(hkintl)) {
  hkintl.earth <- earth(reducedvis~.,data=hkintl[-i,],
                      glm=list(family=binomial),keepxy=T,nfold=1,penalty=5)
  earth.pred[i] <- predict(hkintl.earth,newdata=hkintl[i,],type="response")
}

earth.pred <- as.factor(ifelse(earth.pred>0.5,"yes","no"))
earth.acc <- sum(earth.pred==hkintl$reducedvis)/nrow(hkintl)
table(earth.pred,hkintl$reducedvis)

hkintl.earth <- earth(reducedvis~.,data=hkintl,
                      glm=list(family=binomial),keepxy=T,nfold=10,penalty=5)
earth.fitted <- as.factor(ifelse(hkintl.earth$fitted.values>0.5,"yes","no"))
sum(earth.fitted==hkintl$reducedvis)/nrow(hkintl)


library(bartMachine)
bart.pred <- vector("numeric",nrow(hkintl))
for (i in 1:nrow(hkintl)) {
  hkintl.bart <- bartMachine(X=hkintl[-i,-1],y=hkintl[-i,1])
  bart.pred[i] <- predict(hkintl.bart,new_data=hkintl[i,-1],type="class")
  # destroy_bart_machine(hkintl.bart)
}
bart.pred <- as.factor(ifelse(bart.pred==1,"no","yes"))
bart.acc <- sum(bart.pred==hkintl$reducedvis)/nrow(hkintl)
table(bart.pred,hkintl$reducedvis)

hkintl.bart <- bartMachine(X=hkintl[,-1],y=hkintl[,1],serialize=T)
hkintl.bart$confusion_matrix
summary(hkintl.bart)

library(nnet)
set.seed(7)
ann.acc <- vector("numeric",10)
ann.pred <- vector("numeric",nrow(hkintl))
ann.pred <- matrix(0,nrow(hkintl),10)
for (j in 1:10) {
  for (i in 1:nrow(hkintl)) {
    hkintl.ann <- nnet(reducedvis~.,size=10,data=hkintl[-i,],decay=1)
    ann.pred[i,j] <- predict(hkintl.ann,newdata=hkintl[i,],type="class")
  }
  ann.acc[j] <- sum(ann.pred[,j]==hkintl$reducedvis)/nrow(hkintl)
}
table(ann.pred,hkintl$reducedvis)
hkintl.ann <- nnet(reducedvis~.,size=10,data=hkintl,decay=1)
table(predict(hkintl.ann,newdata=hkintl,type="class"),hkintl$reducedvis)
sum(predict(hkintl.ann,newdata=hkintl,type="class")==hkintl$reducedvis)/nrow(hkintl)

hkintl.avnn <- avNNet(reducedvis~.,data=hkintl,size=10,repeats=10)
