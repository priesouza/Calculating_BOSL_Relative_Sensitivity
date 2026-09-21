###Output saving preferences
output_file <- "Example_Tn_sensitivity"
exporting.format <- "csv" #Excel or csv

###Input data
##Selection with an R fuction
path <- rstudioapi::selectDirectory(caption = "Select the folder containing the .binx file")
setwd(paste0(path))
sample <- basename(file.choose()) #select the file to be analysed

##Alternative: manually specify the input data path
#path <- "C:/Users/example/" #specify where the working file is
#setwd(paste0(path))
#sample <- "EXAMPLE_Quartz_OSL_dating.binx" #specify the name of the file to be analysed

###Measurement settings
mode <- "horizontally" #specify if the measurement was ran "vertically" or "horizontally"
Tn_run <- 6
#Tn_set <- 3 #specify it only if necessary, i.e., when the sequence was ran vertically 

t.stim <- 40 #specify duration (in seconds) of light stimulation
tot.channels <- 400 #specify how many channels were recorded
sg1 <- 1 #specify in what channel the signal integration begins
sg2 <- 10 #specify in what channel the signal integration ends 
bg1 <- 301 #specify in what channel the background begins
bg2 <- tot.channels #specify in what channel the background ends
sti.power = 80*0.9 #the reader operating stimulation power
LED.wl = 470 #LED wavelength

components = 3 #how many components are assumed for the signal deconvolution (max =4)

#install.packages(c("rstudioapi","Luminescence","openxlsx","dplyr")) #if necessary; else, just mute the line

#######################################################################
################## nothing else to change/specify #####################
################ just press ctrl+A and enter to run ###################
#######################################################################

#Loading packages
library("rstudioapi");library("Luminescence"); library("openxlsx"); library("dplyr")

#Reading the data
Tn_signal <- read_BIN2R(paste(sample, sep = ""))

if (mode == "horizontally") {
  Tn_signal <- subset(Tn_signal, Tn_signal@METADATA$RUN == Tn_run)
  } else {
  Tn_signal <- subset(Tn_signal, Tn_signal@METADATA$RUN == Tn_run & Tn_signal@METADATA$SET == Tn_set)
}

Tn_signal <- data.frame(Tn_signal@DATA)

#%BOSL1s Sensitivity calculation
osl.s <- bg.osl <- osl.total <- bg.total <- sens.osl <- osl <- 1:length(Tn_signal)
sens <- sd.bg.osl <- lower.limit <- 1:length(Tn_signal) 

for (i in 1:length(Tn_signal)) {
  
  osl.s[i] = sum(Tn_signal[,i][sg1:sg2])
  osl.total[i] = sum(Tn_signal[,i][1:bg2])
  bg.osl[i] = mean(Tn_signal[,i][bg1:bg2])*length(Tn_signal[,i][sg1:sg2])
  bg.total[i] = mean(Tn_signal[,i][bg1:bg2])*length(Tn_signal[,i][1:bg2])
  sd.bg.osl[i] = sd(Tn_signal[,i][bg1:bg2])
  lower.limit[i] = bg.osl[i]+(3*sd.bg.osl[i])
  
  # OSL in cts/1s
  osl[i] = osl.s[i]-bg.osl[i]
  # %BOSLF
  sens.osl[i] = osl[i]/(osl.total[i]-bg.total[i])*100
 
   if (osl[i] < lower.limit[i]) {
    sens[i] = "dim"
  } else if
    (osl[i] > lower.limit[i]) {
      sens[i] = sens.osl[i]
    }
  }
  
#Signal deconvolution
fast.prop <- med.prop <- slow.prop <- slow.2.prop <- 1:length(Tn_signal)
fast <- med <- slow <- slow.2 <- 1:length(Tn_signal)

data.res <- t.stim/tot.channels
t <- seq(data.res,data.res*bg2,data.res)

for (i in 1:length(Tn_signal)) {
  fit = fit_CWCurve(data.frame(t,Tn_signal[,i]), n.components.max = components, fit.method = "LM",
                    fit.trace = F, fit.failure_threshold = T, 
                    LED.power = sti.power, LED.wavelength = LED.wl,
                    #log = "x",
                    plot = F)
  if (ncol(fit$component.contribution.matrix[[1]]) == 15) {
    fast.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])/
                      (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c4"][sg1:sg2])))*100
    med.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])/
                     (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                        sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])+
                        sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])+
                        sum(fit$component.contribution.matrix[[1]][,"cont.c4"][sg1:sg2])))*100
    slow.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])/
                      (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c4"][sg1:sg2])))*100
    slow.2.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c4"][sg1:sg2])/
                      (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c4"][sg1:sg2])))*100
    fast[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c1"])
    med[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c2"])
    slow[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c3"])
    slow.2[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c4"])
  }
  if (ncol(fit$component.contribution.matrix[[1]]) == 12) {
    fast.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])/
                      (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])))*100
    med.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])/
                     (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                        sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])+
                        sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])))*100
    slow.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])/
                      (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c3"][sg1:sg2])))*100
    slow.2.prop[i] = print(NA)
    fast[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c1"])
    med[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c2"])
    slow[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c3"])
    slow.2[i] = data.frame(print(NA))
  }
  if (ncol(fit$component.contribution.matrix[[1]]) == 9) {
    fast.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])/
                      (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                         sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])))*100
    med.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])/
                     (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])+
                        sum(fit$component.contribution.matrix[[1]][,"cont.c2"][sg1:sg2])))*100
    slow.prop[i] = print(NA)
    slow.2.prop[i] = print(NA)
    fast[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c1"])
    med[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c2"])
    slow[i] = data.frame(print(NA))
    slow.2[i] = data.frame(print(NA))
    
  }
  if(ncol(fit$component.contribution.matrix[[1]]) == 6) {
    fast.prop[i] = (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])/
                      (sum(fit$component.contribution.matrix[[1]][,"cont.c1"][sg1:sg2])))*100
    med.prop[i] = print(NA)
    slow.prop[i] = print(NA)
    slow.2.prop[i] = print(NA)
    fast[i] = data.frame(fit$component.contribution.matrix[[1]][,"cont.c1"])
    med[i] = data.frame(print(NA))
    slow[i] = data.frame(print(NA))
    slow.2[i] = data.frame(print(NA))
  }
}

#Condensing the results
comp.prop = data.frame(sens, fast.prop, med.prop, slow.prop)
colnames(comp.prop) = c("%BOSLf","fast (% of BOSLf)", "medium (% of BOSLf)", "slow (% of BOSLf)")
osl.comp = data.frame(osl, osl*fast.prop/100, osl*med.prop/100, osl*slow.prop/100)
colnames(osl.comp) = c("OSL (cts/1s)","fast (cts/1s)", "med (cts/1s)", "slow (cts/1s)")
comp = data.frame(mean(fast.prop), mean(na.omit(med.prop)), mean(na.omit(slow.prop)))
comp.sd = data.frame(sd(fast.prop), sd(na.omit(med.prop)), sd(na.omit(slow.prop)))
comp.se = data.frame(sd(fast.prop)/(sqrt(length(fast.prop))), 
                     sd(na.omit(med.prop))/(sqrt(length(med.prop))), 
                     sd(na.omit(slow.prop))/(sqrt(length(slow.prop))))

aliquot <- c(1:length(Tn_signal))

#Saving
if (exporting.format == "Excel"){
  table = cbind(aliquot,comp.prop, osl.comp)
  write.xlsx(table, file = paste0(output_file, ".xlsx"), sheetName = "Tn_sensitivity")
} else {
  write.csv(table, paste0(output_file,".csv"))
}

