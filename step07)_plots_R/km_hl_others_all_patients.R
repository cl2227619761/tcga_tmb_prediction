# function to plot KM curves
# high_low vs others for all patients

# load packages
library(survival)
library(survminer)
library(dplyr)
library(readxl)
library(R.matlab)
library(openxlsx)

data_path0<-"E:/Hongming/projects/tcga-bladder-mutationburden/tcga_tmb_prediction/step07)_plots_R/patients_all/"
pid_tmb_pred<-read_excel(paste(data_path0,"pid_tmb_pred.xlsx",sep=""),sheet = "Sheet1")

#data_path0<-"E:/Hongming/projects/tcga-bladder-mutationburden/heatmap_blca/"
#pid_pred_gt<-read_excel(paste(data_path0,"pid_pred_gt.xlsx",sep=""),sheet = "Sheet1")

data_path1<-"E:/Hongming/projects/tcga-bladder-mutationburden/tcga_tmb_prediction/step07)_plots_R/patients_all/"
entropy_all<-read_excel(paste(data_path1,"entropy_all.xlsx",sep=""),sheet = "Sheet1")
pvalue<-entropy_all$entropy
pid<-entropy_all$`patient ID`

data_path1<-"E:/Hongming/papers/2020 cancer patient tmb prediction/TMB_Manuscript/supplement/"
sup_tab<-read_excel(paste(data_path1,"temp.xlsx",sep=""),sheet="Sheet1")

# plot the histogram of entropy
hist(pvalue, breaks = 50)

plabel<-vector()
plabel1<-vector()

tt<-quantile(as.numeric(pvalue),c(0.3,0.4,0.5,0.6,0.7))
plabel1<-(pvalue>tt[3])
plabel1[plabel1==TRUE]<-'High'
plabel1[plabel1==FALSE]<-'Low'

# plot the histogram of entropy
hist(pvalue, main='Histogram of entropy values',xlab="Entropy Value", ylab="Frequency",breaks = 50)
abline(v=tt[3],col='red',lwd=3, lty=2)

for (kk in 1:length(pid)){
  temp_pID<-substring(as.character(pid[kk]),2,24)
  for (jj in 1:length(pid_tmb_pred$`patient_names`))
    if (temp_pID==substring(as.character(pid_tmb_pred$`patient_names`[jj]),1,23)){
      plabel[kk]<-paste(pid_tmb_pred$preds[jj],'-',plabel1[kk],sep="")
      break
    }
}

pid2<-vector()
plabel2<-vector()
ind=1
for (kk in 1:length(pid)){
  if (plabel[kk]=="High-Low") {
    #pid2[ind]<-substring(pid[kk],2,24)
    pid2[ind]<-substring(pid[kk],2,13)
    plabel2[ind]<-plabel[kk]
    ind<-ind+1
  } else if (plabel[kk]=="High-High"){
    pid2[ind]<-substring(pid[kk],2,13)
    plabel2[ind]<-"Others"
    ind<-ind+1
  } else if (plabel[kk]=="Low-Low") {
    pid2[ind]<-substring(pid[kk],2,13)
    plabel2[ind]<-"Others"
    ind<-ind+1
  } else if(plabel[kk]=="Low-High"){
    pid2[ind]<-substring(pid[kk],2,13)
    plabel2[ind]<-"Others"
    ind<-ind+1
  }
  else {
    print('skip!')
  }
}

# generate sup files
fig<-vector()
for (nn in 1 :length(sup_tab$`Case ID`)){
  temp_pID=as.character(sup_tab$`Case ID`[nn])
  
  ind<-which(pid2==temp_pID)
  
  if (length(ind)==1) {
    fig<-c(fig,plabel2[ind])
  } else {
    fig<-c(fig,'NA')
  }
}
sup_tab['Fig5.(a)']<-fig
#write.xlsx(sup_tab, paste(data_path1,"temp1.xlsx",sep=""), sheetName = "Sheet1")

blca_pred<-data.frame("patientID"=Reduce(rbind,pid2),"label_class"=Reduce(rbind,plabel2))
#write.xlsx(blca,"blca.xlsx")

data_path<-"E:/Hongming/projects/tcga-bladder-mutationburden/tcga_tmb_prediction/step00)_preprocessing/"
blca_data<-read_excel(paste(data_path,"Table_S1.2017_08_05.xlsx",sep=""),sheet="Master table")


futime<-vector()
fustat<-vector()
for (nn in 1:length(blca_pred$patientID))
{
  temp_pID=as.character(blca_pred$patientID[nn])
  for (kk in 1:length(blca_data$`Case ID`))
  {
    if (temp_pID==as.character(blca_data$`Case ID`[kk]))
    {
      futime<-c(futime,as.numeric(blca_data$`Combined days to last followup or death`[kk])/30.0)
      fustat<-c(fustat,as.character(blca_data$`Vital status`[kk]))
      break
    }
  }
}

blca_pred$futime<-futime
blca_pred$fustat<-fustat

row_ind<-which(is.na(blca_pred$futime))
if (length(row_ind)>0) {
  blca_pred<-blca_pred[-c(row_ind),]   # remove two not available patients
}

row_ind2<-which(blca_pred$futime<0)
if (length(row_ind2)>0){
  blca_pred<-blca_pred[-c(row_ind2),]
}


# dichotomize the dead/alive and change data labels
# dead: censored 1, alive 0
blca_pred$fustat <- factor(blca_pred$fustat,
                           levels=c("Dead","Alive"),
                           labels=c("1","0"))

blca_pred$futime<-as.numeric(as.character(blca_pred$futime)) # note that: must be numeric type
blca_pred$fustat<-as.numeric(as.character(blca_pred$fustat)) # note that: must be numeric type


# fit survival data using the kaplan-Meier method
surv_object<-Surv(time=blca_pred$futime,event=blca_pred$fustat)
# surv_object

fit1<-survfit(surv_object~label_class,data=blca_pred)
# summary(fit1)

#setEPS()
#postscript("whatever.eps")

ggsurvplot(fit1,pval = TRUE,
           #risk.table = TRUE, 
           legend=c(0.75,0.85),
           legend.labs=c("High-Low (76)","Others (292)"),
           legend.title="Categories",
           xlab="Time in months")+ggtitle("TCGA BLCA (n=368)")

#dev.off()
ggsave(filename = "km_2class_all3.eps",
       fallback_resolution = 600,
       device = cairo_ps)



