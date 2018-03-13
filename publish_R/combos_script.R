###
### REDO ALL ANALYSES: AIM IS TO PUBLISH SCRIPT FROM RAW DATA
### author: Arnaud Amzallag

### install these 3 R packages first:
library(dplyr) # 0.7.2
library(reshape2) # 1.4.2
library(ggplot2) # 2.2.1.9000
library(readr) # 1.0.0

##
## R AND PACKAGES VERSIONS FOR REPRODUCIBILITY: 
## Results may vary if another version of R or packages is used.
##
# sessionInfo()
# R version 3.3.2 (2016-10-31)
# Platform: x86_64-apple-darwin13.4.0 (64-bit)
# Running under: macOS Sierra 10.12.6
# 
# locale:
#   [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
# 
# attached base packages:
#   [1] stats     graphics  grDevices utils     datasets  methods   base     
# 
# other attached packages:
#   [1] readr_1.0.0        bindrcpp_0.2       ggplot2_2.2.1.9000 reshape2_1.4.2     dplyr_0.7.2       
# 
# loaded via a namespace (and not attached):
#   [1] Rcpp_0.12.12      digest_0.6.12     assertthat_0.2.0  grid_3.3.2        R6_2.2.2         
# [6] plyr_1.8.4        gtable_0.2.0      magrittr_1.5      scales_0.4.1.9002 rlang_0.1.1      
# [11] stringi_1.1.5     lazyeval_0.2.0    labeling_0.3      tools_3.3.2       stringr_1.1.0    
# [16] glue_1.1.1        munsell_0.4.3     colorspace_1.3-1  pkgconfig_2.0.1   bindr_0.1        
# [21] tibble_1.3.3     

outdir <- "newoutdir"
dir.create(outdir)

## LOADING THE RAW DATA
#rawscreen <- readRDS(file=file.path(".", "rawscreen.rds"))
rawscreen <- read_csv("http://a-a-public-bucket.s3.amazonaws.com/rawscreen.csv.gz")

## COLUMN and ROW determine the position on the plate
## Nuclei is the counted number of
## DAPI stained nuclei in the well (image software: MetaXpress)
## cPARP is a subset of the DAPI cell that have been tagged as apoptotic by cleaved Parp staining. 

## MEDIAN POLISH
## this is a special median polish function that logs the data before polish, 
## and re-exponentiates at the end. It works with some zeros (they become -Inf)
## and as long as medians are not -Inf, it works (never tried with many -Inf)
## Anyway, we add 1 to Nuclei before median polish
medpol <- function(df, myvar, toler = 0.01, maxiter = 100, print.diff = FALSE) {
  require(dplyr)
#  print(paste(df$cell.line[1], df$plate[1]))
  res <- df
  newvarname <- paste(myvar, "new", sep=".")
  res[["newvar"]] <- -log10(res[[myvar]])
  tot <- median(res[["newvar"]], na.rm=TRUE)
  maxdiff <- 13
  notfirst <- FALSE
  cpt <- 1
  while (maxdiff > toler & cpt <= maxiter) {
    res <- group_by(res, COLUMN, add = FALSE) %>% mutate(newvar = newvar - median(newvar, na.rm=TRUE))
    res <- group_by(res, ROW, add = FALSE) %>% mutate(newvar = newvar - median(newvar, na.rm=TRUE))
    if (notfirst) {
      tmpdiff <- abs(10^-res$newvar - 10^-lastmat)
      maxdiff <- max(tmpdiff, na.rm = TRUE)
      if (print.diff & notfirst)  print(sprintf("mean diff: %f - max diff: %f", mean(tmpdiff, na.rm = TRUE), maxdiff))    
    }
    lastmat <- res$newvar
    notfirst <- TRUE
    cpt <- cpt+1
  }
  res[[newvarname]] <- 10^(-res[["newvar"]] - tot) # RESTORE THE ORIGINAL MEDIAN
  res$"newvar" <- NULL
  return(res)
}

## add 1 to nuclei
raws <- mutate(rawscreen, Nuclei = pmax(1, Nuclei))

## Apply median polish values to each plate using grouping and chaining syntax from dplyr 2.0 (takes a few seconds)
rawss <- group_by(raws, cell.line, plate, add = FALSE) %>%
		 mutate(Nuclei.new = medpol(data.frame(COLUMN=COLUMN, ROW=ROW, 
								   cell.line=cell.line, plate=plate, Nuclei=Nuclei), "Nuclei")$Nuclei.new) # to convergence; takes a few seconds

rawst <- group_by(raws, cell.line, plate, add = FALSE) %>%
		 mutate(Nuclei.new = medpol(data.frame(COLUMN=COLUMN, ROW=ROW,
								    cell.line=cell.line, plate=plate, Nuclei=Nuclei), "Nuclei", maxiter=1)$Nuclei.new) # one iteration only

rawst$Nuclei.new.iterpol <- rawss$Nuclei.new
rm(rawss)
# rawss  <- as.data.frame(rawst)

## OPTIONAL PLOT: compare median polish: one-pass vs convergence. No big difference. We use the one pass for historical reasons.
png(file.path(outdir, "median.polish_one_iter_vs_converge.png"), type="cairo")
qplot(Nuclei.new, Nuclei.new.iterpol, data = rawst)
dev.off()


## Compute Viabilities
raws <- group_by(rawst, cell.line, plate, add = FALSE) %>% mutate(
  viab = Nuclei.new / mean(subset(Nuclei.new, Drug1 %in% "DMSO" & Drug2 %in% "DMSO"), na.rm = TRUE, trim = 0.1), 
  viab.nopol = Nuclei / mean(subset(Nuclei, Drug1 %in% "DMSO" & Drug2 %in% "DMSO"), na.rm = TRUE, trim = 0.1),
  cPARP.norm = cPARP / mean(subset(cPARP, Drug1 %in% "DMSO" & Drug2 %in% "DMSO"), na.rm = TRUE, trim = 0.1),
  c.prop = cPARP / Nuclei
)

## OPTIONAL PLOT: SEE CHANGE IN VIABILITY DONE BY THE MEDIAN POLISH (~ 20 seconds)
png(file.path(outdir, "median.polish_or_not.png"), type="cairo", he=1200, wi=1200)
qplot(viab.nopol, viab, alpha=I(0.2), colour = factor(plate), data = raws) + facet_wrap(~ cell.line, scale="free")
dev.off()


raws$ROW <- factor(raws$ROW, levels = c(toupper(letters), paste("A", toupper(letters)[1:6], sep="")))
raws$Drug1 <- factor(raws$Drug1)
raws$Drug2 <- factor(raws$Drug2)

## SAVE INTERMEDIATE FILE WITH VIABILITIES
saveRDS(raws, file=file.path(outdir, "raws.rds"))
## re-load with:
raws <- readRDS(file=file.path(outdir, "raws.rds"))

## LINEAR MODEL WITH CALCULATED SINGLETS
## FUNCTION CREATES DESIGN MATRIX FROM THE DATA AND SOLVES THE SYSTEM, 
## RETURNS A lm OBJECT
# function for solving the model of independence of drug effects per cell line:
# log(V_i) + log(V_j) ~ log(V_{ij})
# 
regress.combos <- function(tmp) {
  require(reshape2)
  print(tmp$cell.line[1])
  tmp <- droplevels(subset(tmp, is.finite(viab)))
  #print(dim(tmp))
  # UNIFY LEVELS OF DRUG1 AND DRUG2
  tmp <- mutate(tmp,
                Drug1 = factor(Drug1, levels = union(levels(Drug1), levels(Drug2))),
                Drug2 = factor(Drug2, levels = union(levels(Drug1), levels(Drug2)))
  )
  
  ## CREATE DESIGN MATRIX FOR Drug1, then for Drug2, then sum them to get a unique column per drug in the design matrix!
  # Create an id for the well with paste; necessary to join fitted values and residuals to the original data
  tmp   <- mutate(tmp, id = paste(ROW, COLUMN, plate, sep="_"))
  tmpc  <- acast(tmp, id ~ Drug1, fill=0, length, drop = FALSE)
  tmpc2 <- acast(tmp, id ~ Drug2, fill=0, length, drop = FALSE)
  #identical(colnames(tmpc), colnames(tmpc2)) # TRUE because Drug1 levels and Drug2 levels are the same, and we used drop = FALSE 
  #identical(rownames(tmpc), rownames(tmpc2)) # TRUE
  desmat <- tmpc + tmpc2
  desmat <- desmat[tmp$id, ]
  
  ## Regression:
#  singlet.lm <- lm(-log10(tmp[, "viab"]) ~ desmat + 0)
  singlet.lm <- with(tmp, lm(-log10(viab) ~ desmat + 0))
  return(list(tmp.id=tmp$id, lm.obj=singlet.lm))
}

## APPLY REGRESSION TO ALL CELL LINES AT EACH CONCENTRACTION (HIGH OR LOW), SEPARATELY ONE BY ONE (takes a couple of minutes)
cell.names <- unique(raws$cell.line)
lms <- lapply(cell.names, function(cell.name) regress.combos(subset(raws, cell.line %in% cell.name & !(Drug1 %in% "DMSO" | Drug2 %in% "DMSO"))))
names(lms) <- cell.names

## DO ALSO WITHOUT MEDIAN POLISH (also takes a couple of minutes)
lms.nopol <- lapply(cell.names, function(cell.name) {
  rawstmp <- mutate(raws, viab = viab.nopol)
  regress.combos(subset(rawstmp, cell.line %in% cell.name & !(Drug1 %in% "DMSO" | Drug2 %in% "DMSO")))
}
)
names(lms.nopol) <- cell.names

## GET FITTED AND RESIDUALS FROM LM OBJECTS
# add cell.line to id, get fitted and residuals in a data.frame "lms.df"
lms.df <- lapply(names(lms), function(k) data.frame(id=paste(k, lms[[k]]$tmp.id, sep=" "), fitted=lms[[k]]$lm.obj$fitted.values, residuals=lms[[k]]$lm.obj$residuals))
lms.df <- do.call(rbind, lms.df)
## JOIN WITH raws
# Create id to match id from regress.combos() function 

raws$id <- factor(with(raws, paste(cell.line, paste(ROW, COLUMN, plate, sep="_"))))
raws <- raws[, c(ncol(raws), 1:(ncol(raws)-1))] # put id as first column
raws <- left_join(raws, lms.df, by="id")

## PLOT: for 3 cell lines, plot predicted combo viability (y axis) vs observed (x axis)
png(file.path(".", outdir, "fitted_vs_actual_combos_3_lines.png"), type="cairo", he=300, wi=600)
qplot(x=fitted+residuals, y=fitted, data=subset(raws, cell.line %in% c("CBRC008_lo", "CBRC013", "CBRC013_lo"))) + facet_wrap(~ cell.line) + geom_abline(slope=1)
dev.off()

## ADD SINGLETS COLUMNS AND STANDARD BLISS
##
tmpsing <- subset(ungroup(raws), Drug1 %in% "DMSO" & !(Drug2 %in% "DMSO")) %>% select(cell.line, Drug2, viab)
colnames(tmpsing)[3] <- "viab.sing2"
raws <- left_join(raws, tmpsing)
colnames(tmpsing)[2] <- "Drug1"
colnames(tmpsing)[3] <- "viab.sing1"
raws <- left_join(raws, tmpsing)
# BLISS
raws$bliss <- with(raws, viab.sing1*viab.sing2 - viab)

###
### Need to add singlet standard error!
### EXTRACT SINGLET INFORMATION FROM THE MODEL
###
singlets.df <- lapply(names(lms), function(k) {
  sings <- coef(summary(lms[[k]]$lm.obj))[, 1:2]
  colnames(sings) <- c("est.log.sing", "sd.log.sing")
  res <- data.frame(cell.line=k, Drug=sub("^desmat", "", rownames(sings)), sings)
  rownames(res) <- NULL 
  return(res)
})
singletsdf <- do.call(rbind, singlets.df)
#singletsdf$cell.line <- as.character(singletsdf$cell.line)
head(singletsdf)

### THE LINEAR MODEL USED THE COMBINATION VIABILITIES FROM THE PLATE
### AND THE BLISS INDEPENDENCE ASSUMPTION TO SOLVE FOR THE SINGLET VIABILITIES.
### HOW DO THE SOLUTIONS (SINGLET VIABILITES) COMPARE TO THE 
### OBSERVED SINGLET VIABILITIES ?
### SCATTER PLOT OF ESTIMATED SINGLET VIABILITIES VERSUS OBSERVED SINGLET VIABILITIES:
colnames(tmpsing) <- c("cell.line", "Drug", "viab.sing")
tmpsinglet <- left_join(tmpsing, singletsdf)
tmpsinglet$conc <- with(tmpsinglet, ifelse(grepl("_lo$", cell.line), "low", "high"))
tmpsinglet$cell.line2 <- sub("_lo$", "", tmpsinglet$cell.line)

write.csv(tmpsinglet, row.names=FALSE, file=file.path(".", outdir, "singlets_viabilites.csv"))

## ONE PANEL PER CELL LINE 
pdf(file.path(".", outdir, "singlets_measured_vs_regressed.pdf"), he=20, wi=20)
qplot(viab.sing, 10^-est.log.sing, data=subset(tmpsinglet, !grepl("_lo$", cell.line))) + xlab("Measured viability") + ylab("Regressed viability") +
		facet_wrap(~ cell.line, scale="free") + coord_fixed() + geom_abline(slope=1) + ggtitle("High dose")
qplot(viab.sing, 10^-est.log.sing, data=subset(tmpsinglet, grepl("_lo$", cell.line))) + xlab("Measured viability") + ylab("Regressed viability") +
		facet_wrap(~ cell.line, scale="free") + coord_fixed() + geom_abline(slope=1) + ggtitle("Low dose")
dev.off()

## ONE PANEL PER DRUG
pdf(file.path(".", outdir, "singlets_measured_vs_regressed_per_drug.pdf"), he=45, wi=15)
qplot(viab.sing, 10^-est.log.sing, data=subset(tmpsinglet, conc=="high")) + xlab("Measured viability") + ylab("Regressed viability") +
		facet_wrap(~ Drug, scale="free", ncol=6) + coord_cartesian(xlim=c(0, 1.5), ylim=c(0, 1.5)) + geom_abline(slope=1) + ggtitle("High dose")
qplot(viab.sing, 10^-est.log.sing, data=subset(tmpsinglet, conc=="low")) + xlab("Measured viability") + ylab("Regressed viability") +
		facet_wrap(~ Drug, scale="free", ncol=6) + coord_cartesian(xlim=c(0, 1.5), ylim=c(0, 1.5)) + geom_abline(slope=1) + ggtitle("Low dose")
dev.off()



## ADD SINGLET ESTIMATES and BLISS FROM SINGLET ESTIMATES
tmpsingletsdf <- singletsdf
colnames(tmpsingletsdf)[2:4] <- paste(colnames(singletsdf)[2:4], "1", sep="")
raws <- left_join(raws, tmpsingletsdf)
colnames(tmpsingletsdf)[2:4] <- paste(colnames(singletsdf)[2:4], "2", sep="")
raws <- left_join(raws, tmpsingletsdf)

raws$bliss.est <-  with(raws, 10^(-est.log.sing1)*10^(-est.log.sing2) - viab)
saveRDS(raws, file=file.path(".", outdir, "raws.rds"))

###
### Rss: EXCTRACT THE R SQUARED FROM THE LM OBJECTS, PLOT
###

#lms.nopol <- readRDS(file="~/aamzallag/projects/CMT/Combos/combos07.output/lms.nopol.rds")
#Rs <- sapply(function(x) summary(x$lm.obj)$r.squared)

identical(names(lms.nopol), names(lms)) # TRUE
Rs <- data.frame(cell.line=factor(names(lms.nopol)), r.squared=sapply(lms, function(x) summary(x$lm.obj)$r.squared), r.squared.nopol=sapply(lms.nopol, function(x) summary(x$lm.obj)$r.squared), sigma=sapply(lms, function(x) summary(x$lm.obj)$sigma), sigma.nopol=sapply(lms.nopol, function(x) summary(x$lm.obj)$sigma), stringsAsFactors = FALSE)
Rs2 <- raws %>% group_by(cell.line, add = FALSE) %>% summarize(noise.control.log=sd(-log10(viab[Drug1 %in% "DMSO" & Drug2 %in% "DMSO"]), na.rm=TRUE), noise.control=sd(viab[Drug1 %in% "DMSO" & Drug2 %in% "DMSO"], na.rm=TRUE)) %>% arrange(-noise.control)
Rss <- left_join(Rs2, Rs)

## SAVE R SQUARED TABLE
Rss$cell.line <- as.character(Rss$cell.line)
saveRDS(Rss, file=file.path(".", outdir, "Rss.rds"))

## ADD TO MAIN TABLE
rawstt <- left_join(raws, select(Rss, cell.line, r.squared, sigma))

## SAVE MAIN TABLE WITH ESTIMATED SINGLET VALUES AND R SQUARED
saveRDS(rawstt, file=file.path(".", outdir, "rawstt.rds"))

##
## Rss PLOT: COMPARE NOISE FROM CONTROLS AND NOISE FROM MODEL 
##
pdf(file.path(".", outdir, "sigma_vs_control_noise.pdf"))
qplot(noise.control.log, sigma, colour=c("low", "high")[1+!grepl("_lo", cell.line)], data=Rss) + geom_abline(slope = 1) + theme_bw() + 
		geom_text(aes(label = ifelse(noise.control.log>0.4, cell.line, "")), colour="black", hjust = 1.1, vjust=1.2, show_guide=FALSE) + 
		scale_colour_manual(name = "Drug conc.", values = c(high="black", low="gray60")) + coord_fixed()
dev.off()

## ANOTHER PLOT WITH Rss : R SQUARED
## R SQUARED IS A MEASURE OF THE GOODNESS OF FIT OF A STATISTICAL MODEL.
## THE HIGHER THE BETTER AND THE MAXIMUM IS 1.
## HERE WE PLOT A TWO PAGE PDF WITH THE R SQUARED OF ALL THE MODELS WE FITTED.
## THERE IS ONE MODEL PER CELL LINE PER CONCENTRATION.
## THE GRAY BARS REPRESENT THE R SQUARED WHEN *NOT* USING THE MEDIAN POLISH. THEY ARE ALMOST
## ALL THE TIME LOWER THAN WHEN USING THE MEDIAN POLISH.
pdf(file.path(".", outdir, "R_squared_plots.pdf"), he=5, wi=7)
## cosmetique: ggplot expression for plot Rsm with the parameters we need, for all graphs below (colour, style of plot, etc)
## we evaluate the expression two times below, after modification of the data to be plotted (Rsm)
cosmetique <- expression(ggplot(Rsm, aes(x=cell.line, y=value, fill=variable)) +  geom_bar(stat="identity", position="dodge") + 
				scale_fill_manual(name = "Median Polish", values = c(r.squared="black", r.squared.nopol="gray60"), 
						labels=c(r.squared="Yes", r.squared.nopol="No")) + theme_bw() + theme(axis.text.x = element_text(angle=290, hjust=0)) +
				ylab("R squared"))

Rsm <- melt(subset(Rss, !grepl("_lo", cell.line)) %>% select(cell.line, r.squared, r.squared.nopol), id.var="cell.line")
Rsm$cell.line <- with(Rsm, reorder(cell.line, value))
eval(cosmetique) + ggtitle("High Concentration Assay") 
Rsm <- melt(subset(Rss, grepl("_lo", cell.line)) %>% select(cell.line, r.squared, r.squared.nopol), id.var="cell.line")
Rsm$cell.line <- with(Rsm, reorder(cell.line, value))
eval(cosmetique) + ggtitle("Low Concentration Assay")

dev.off()

### COMPUTE P VALUES !
###
### THE ASSUMPTION OF THE MODEL WE USED IS INDEPENDENCE (ADDITIVITY) OF THE DRUG EFFECTS,
### I.E. THEIR IS NO SYNERGY.
### THEREFORE DATA POINTS THAT HAVE A MUCH SMALLER THAN PREDICTED BY THE MODEL ARE SYNERGIC.
### SINCE WE USED NEGATIVE LOG10 VIABILITY, LARGE RESIDUALS INDICATE SYNERGY.
### TO DETERMINE HOW LARGE A RESIDUAL IS, WE COMPARE THE RESIDUAL TO THE MEASUREMENT ERROR (NOISE).
### WE TRIED DIFFERENT METHODS TO ESTIMATE NOISE. 
### IN THE FOLLOW UP STUDIES WE ESTIMATE THE NOISE FROM THE STANDARD DEVIATION IN THE CONTROL WELLS (FIELD noise.control.log)
### SEPARATELY FOR EACH CELL LINE. WE ADDED THE ERROR BAR AROUND THE SINGLET VIABILITIES (noise total)

## P VALUES ARE COMPUTED BELOW IN A DPLYR EXPRESSION


## Then convert to variance, add, square root back to SD, and we will have better p values !
## pval.c: noise estimated from control wells only (previous method)
## pval.s: noise estimated from model's sigma only: contains variance from assay noise and real synergies
## pval: noise estimated from control wells AND error bar from singlet estimate
## pval.m: pval for measured bliss (not implemented: in that case we would use 3 times the control well noise: 
## to model the noise in the combination, one for each singlet viability)

rawstt <- group_by(rawstt, cell.line, add = FALSE) %>% mutate(
		          noise.control.log = sd(-log10(viab[Drug1 %in% "DMSO" & Drug2 %in% "DMSO"]), na.rm=TRUE),
		          noise.total = sqrt(noise.control.log^2 + sd.log.sing1^2 + sd.log.sing2^2),
                  zval.c=residuals/noise.control.log, pval.c = 2*pnorm(-abs(zval.c)), padj.c = p.adjust(pval.c, method="BH"), 
                  zval=residuals/noise.total, pval = 2*pnorm(-abs(zval)), padj = p.adjust(pval, method="BH"), 
                  zval.s=residuals/sigma, pval.s = 2*pnorm(-abs(zval.s)), padj.s = p.adjust(pval.s, method="BH")
                  )

## SPLIT CELL LINES NAME AND EXPERIMENT CONCENTRATION IN TWO DISTINCT COLUMNS
rawstt <- ungroup(rawstt)
rawstt$cell.line2 <- sub("_lo$", "", rawstt$cell.line)
rawstt$conc <- c("high", "low")[1+grepl("_lo$", rawstt$cell.line)]
				  
saveRDS(rawstt, file=file.path(".", outdir, "rawstt.rds"))

### OUTPUT THE TABLE IN A CSV FILE
write.csv(select(rawstt, COLUMN, ROW, Drug1, Drug2, Nuclei, cPARP, plate, cell.line2, conc, Nuclei.new, viab, fitted,
				residuals, viab.sing1, viab.sing2, bliss, est.log.sing1, est.log.sing2, bliss.est, zval, padj),
		row.names=FALSE, file=file.path(".", outdir, "screen_results.csv"))

cat("
### DESCRIPTION OF THE COLUMNS:
# 1 COLUMN: plate column
# 2 ROW: plate row
# 3 Drug1: name of the first drug
# 4 Drug2: name of the second drug
# 5 Nuclei: Number of cell nuclei reported by MetaXPress
# 6 cPARP: Number of cPARP positive nuclei reported by MetaXPress
# 7 plate: plate number
# 8 cell.line: cell line/concentration: low drug concentration assay are indicated by the suffix \"_lo\" at the end of the cell line name.
# ## End of raw data
# 
# 9 Nuclei.new: Nuclei after one-pass median polish
# 10 viab: viability: for each plate, it is given by Nuclei.new / mean(DMSO controls Nuclei.new). This is a trimmed mean, where 10% of the control were removed at each extremity of the distribution (20% total)
# 11 fitted: predicted viability of the combo under the drug independence hypothesis (-log10 units)
# 12 residuals: deviation from drug independence : -log10Vij + log10Vi + log10Vj, or log10( (Vi*Vj) / Vij ). Note the relation to the Bliss formula.
# 13 viab.sing1: viability of Drug1 singlet (measured)
# 14 viab.sing2: viability of Drug2 singlet (measured)
# 15 bliss:  (Vi*Vj) - Vij
# 16 est.log.sing1: Inferred Drug1 singlet from the model (-log10 units)
# 17 est.log.sing2: Inferred Drug2 singlet from the model (-log10 units)
# 18 bliss.est: standard Bliss recomputed using inferred singlets instead of measured singlets
# 19 zval: Z value for synergy (positive value is synergy, negative is antagonism)
# 20 padj: p value for synergy
", file = file.path(".", outdir, "screen_results.README.txt"))


### IF YOU DO NOT WANT TO EXECUTE THE PART OF THE SCRIPT ABOVE THIS LINE,
### UNCOMMENT AND EXECUTE NEXT LINE TO START ANALYSIS FROM HERE USING A PRECOMPUTED TABLE; 
### JUST LOAD THE 3 PACKAGES AT THE TOP OF THE SCRIPT FIRST
# rawstt <- readRDS(file.path(".", "precomputed", "rawstt.rds"))


### COMPUTE THE CORRELATION ACROSS CELL LINE BETWEEN HIGH CONCENTRATION VIABILITY AND LOW CONCENTRATION VIABILITY, FOR EACH DRUG
###
### IT IS EXPECTED THAT DRUGS AT DIFFERENT DOSES WITH HAVE DIFFERENT EFFECT. HOWEVER THERE SHOULD BE SOME CORRELATION ACROSS CELL LINES:
### A CELL LINE THAT WAS SENSITIVE AMOND THE MOST SENSITIVES AT LOW DOSE SHOULD ALSO BE AMONG THE MOST SENSITIVES AT HIGH DOSE.
### HERE WE LOOK AT SUCH CORRELATIONS USING THE OBSERVED SINGETS, AND WE COMPARE WITH THE CORRELATIONS FOUND WITH THE ESTIMATED SINGLETS.
###

tmp <- melt(select(tmpsinglet, -cell.line), id.vars=c("Drug", "cell.line2", "conc"))
sing.viabs <- dcast(tmp, Drug + cell.line2 ~ conc + variable, value.var = "value")


## SCATTER PLOTS OF SINGLET VIABILITIES, HIGH VERSUS LOW
pdf(file.path(".", outdir, "singlets_high_vs_low_per_drug.pdf"), he=45, wi=15)
qplot(high_viab.sing, low_viab.sing, data=sing.viabs) + xlab("High dose") + ylab("Low dose") +
		facet_wrap(~ Drug, scale="free", ncol=6) + coord_cartesian(xlim=c(0, 2.5), ylim=c(0, 2.5)) + geom_abline(slope=1) + ggtitle("Observed Singlet Viability")
qplot(10^-high_est.log.sing, 10^-low_est.log.sing, data=sing.viabs) + xlab("High dose") + ylab("Low dose") +
		facet_wrap(~ Drug, scale="free", ncol=6) + coord_cartesian(xlim=c(0, 2.5), ylim=c(0, 2.5)) + geom_abline(slope=1) + ggtitle("Estimated Singlet Viability")
dev.off()


tmpcor <- group_by(sing.viabs, Drug) %>% summarize(measured.singlets.pearson=cor(high_viab.sing, low_viab.sing, use="complete.obs"), 
		estimated.singlets.pearson=cor(10^-high_est.log.sing, 10^-low_est.log.sing, use="complete.obs"))

tmpcor.test <- group_by(sing.viabs, Drug) %>% summarize(measured.singlets.pearson.p=cor.test(high_viab.sing, low_viab.sing, alternative="greater", use="complete.obs")$p.value, 
		estimated.singlets.pearson.p=cor.test(10^-high_est.log.sing, 10^-low_est.log.sing, alternative="greater", use="complete.obs")$p.value, 
		measured.singlets.spearman.p=cor.test(high_viab.sing, low_viab.sing, method="spearman", alternative="greater", use="complete.obs")$p.value, 
		estimated.singlets.spearman.p=cor.test(10^-high_est.log.sing, 10^-low_est.log.sing, alternative="greater", method="spearman", use="complete.obs")$p.value
)

tmpcor <- left_join(tmpcor, tmpcor.test)

as.data.frame(tmpcor[which.min(abs(tmpcor$estimated.singlets.pearson.p-0.05)), ])
as.data.frame(tmpcor[which.min(abs(tmpcor$measured.singlets.pearson.p-0.05)), ]) # 
#Drug measured.singlets.pearson estimated.singlets.pearson
#21 Docetaxel                 0.2783779                  0.6235413
# ...
# -> 0.278 pearson is the significance threshold

### SCATTER PLOT THE CORRELATION MENTIONED ABOVE FOR THE 108 DRUGS
pdf(file.path(".", outdir, "barplot_singlets_high_vs_low_correlations2.pdf"), wi=9, he=15)
tmplot <- tmpcor
tmplot$Drug <- reorder(tmplot$Drug, tmplot$estimated.singlets.pearson)
tmplott <- melt(tmplot) %>% subset(!grepl("\\.p$", variable))
ggplot(tmplott, aes(x=Drug, y=value, fill=variable)) + geom_bar(stat="identity", position="dodge") + geom_hline(yintercept = 0.278) + theme_bw() +
		theme(axis.text.x = element_text(angle=270, hjust=0)) +  ylab("correlation between high and low dose viability, across cell lines") + coord_flip()
dev.off()

### HERE WE SHOW, USING OBSERVED SINGLET VIABILITITES, THAT 32 DRUGS OUT OF 108 HAVE 
### SIGNIFICANT CORRELATION BETWEEN HIGH DOSE AND LOW DOSE ACROSS CELL LINES
### HOWEVER THIS NUMBER INCREASES TO 81 DRUGS OUT OF 108 WHEN USING THE ESTIMATED SINGLET VIABILITIES,
### WHICH IS A STRONG INDICATION THAT WE GET A BETTER ESTIMATION OF THE SINGLET VIABILITIES USING
### THE LINEAR MODEL AND ALL THE COMBINATION DATA RATHER THAN THE SINGLET EXPERIMENTAL WELLS ONLY.
with(tmpcor, sum(measured.singlets.pearson.p<0.05))
# [1] 32 # 32 drugs out of 108 have a significant measured viability correlation between high and low doses 
with(tmpcor, sum(estimated.singlets.pearson.p<0.05))
# [1] 81 # 81 drugs out of 108 have a significant estimated viability correlation between high and low doses 

median(tmpcor$measured.singlets.pearson) # [1] 0.1403375
median(tmpcor$estimated.singlets.pearson) # [1] 0.4863077

####
####  PREPARE DATA FOR HEAT MAP VISUALIZATION (WEB APP)
####

####
####   HERE WE SUMMARIZE THE DATA PER DRUG COMBINATION ACROSS CELL LINES AND DRUG DOSES.
####   FIRST, WE CONSIDER A 4-TUPLE (DRUG 1, DRUG 2, CELL LINE) AS SHOWING SYNERGY IF
####   AT EITHER OF THE TWO DRUG DOSES TESTED WE HAD padj<0.05 and zval>0.
####   THEN WE SUM OVER CELL LINES TO COUNT IN HOW MANY CELL LINES THE DRUG COMBINATION 
####   WAS SYNERGIC.
####
###
###
##
##
#
#




subrawall <- filter(rawstt, !(Drug1 %in% "DMSO"), !(Drug2 %in% "DMSO"))
subrawall$synergic <- as.numeric(subrawall$padj < 0.05 & subrawall$residuals > 0)

### HERE WE COMPARE THE STANDARD BLISS SCORE WITH OUR BLISS SCORE, WHICH USES LOG VIABILITIES INSTEAD OF VIABILITIES.
### COLOR IS THE ADJUSTED P VALUE FOR BEING SYNERGIC ACCORDING TO OUR MODEL.
png(file.path(".", outdir, "bliss.est_vs_zval_high.png"), type="cairo", he=1200, wi=1200)
ggplot(filter(subrawall, conc == "high"), aes(bliss.est, zval, colour = padj < 0.05)) + theme_bw() +
		geom_point(alpha=I(0.2)) + geom_vline(xintercept=0, colour="gray50") + ggtitle("high dose") +
		facet_wrap(~ cell.line2) + xlab("Excess over-Bliss") + geom_hline(yintercept=0, colour="gray50")  
dev.off()

png(file.path(".", outdir, "bliss.est_vs_zval_low.png"), type="cairo", he=1200, wi=1200)
ggplot(filter(subrawall, conc == "low"), aes(bliss.est, zval, colour = padj < 0.05)) + theme_bw() +
		geom_point(alpha=I(0.2)) + geom_vline(xintercept=0, colour="gray50") + ggtitle("high dose") +
		facet_wrap(~ cell.line2) + xlab("Excess over-Bliss") + geom_hline(yintercept=0, colour="gray50")  
dev.off()


synhighlow2 <- group_by(subrawall, Drug1, Drug2, cell.line2) %>% 
  summarize(syner=sum(synergic, na.rm=TRUE), z.max=max(zval, na.rm=TRUE),
            which.syn = paste(conc[as.logical(ifelse(is.na(synergic), 0, synergic))], collapse="_"),
            c.prop = ifelse(length(which.max(zval)>0), c.prop[which.max(zval)], NA),
            viab = ifelse(length(which.max(zval)>0), viab[which.max(zval)], NA)) %>%
  ungroup()

nsyn.all <- group_by(synhighlow2, Drug1, Drug2) %>% summarize(n.syn=sum(syner>0))

## Load data with alternative drug names and known molecular targets
drug.names <- read.csv("plos_drug_names_match_with_targets.csv")
nsyn.all$Drug1.target <- drug.names[match(nsyn.all$Drug1, drug.names$plos.name), "target.plos"]
nsyn.all$Drug2.target <- drug.names[match(nsyn.all$Drug2, drug.names$plos.name), "target.plos"]


## - ADD SPECIFIC SCORE: how far from "sensitizer, ie median # of synergic cell lines per drug"

symmetrize <- function(synhighlow2f) {
	synhighlow2b <- synhighlow2f
	tmp <- synhighlow2b$Drug2; synhighlow2b$Drug2 <- synhighlow2b$Drug1; synhighlow2b$Drug1 <- tmp;
	tmp <- synhighlow2b$Drug2.target; synhighlow2b$Drug2.target <- synhighlow2b$Drug1.target; synhighlow2b$Drug1.target <- tmp;
	return(rbind(synhighlow2f, synhighlow2b))
}

drug.mean <- symmetrize(nsyn.all) %>% group_by(Drug1) %>% summarize(n.syn.mean = mean(n.syn), n.syn.sd = sd(n.syn)) %>% arrange(-n.syn.mean)
colnames(drug.mean) <- c("Drug1", "syn.mean1", "syn.sd1")
nsyn.all <- left_join(nsyn.all, drug.mean)

colnames(drug.mean) <- c("Drug2", "syn.mean2", "syn.sd2")
nsyn.all <- left_join(nsyn.all, drug.mean)

#nsyn.all$n.syn.score <- with(nsyn.all, n.syn - pmax(syn.mean1, syn.mean2)) 
nsyn.all$n.syn.score <- with(nsyn.all, pmin((n.syn - syn.mean1)/syn.sd1, (n.syn - syn.mean2)/syn.sd2)) 
nsyn.all <- arrange(nsyn.all, -n.syn)


#nsyn.all <- arrange(nsyn.all, -n.syn)

### SAVE: 
### THIS SPREADSHEET CONTAINS THE RANKING OF THE MOST SYNERGIC COMBINATIONS, 
### SUMMARIZED OVER CELL LINES AND DOSES.
write.csv(nsyn.all, file.path(".", outdir, "combo_ranking_n.syn_score3.csv"), row.names=FALSE)

nsyn.all.select <- select(nsyn.all, Drug1, Drug2, Drug1.target, Drug2.target, synergy.score = n.syn, specificity.score = n.syn.score)
write.csv(nsyn.all.select, file.path(".", outdir, "Supplementary_Table_1.csv"), row.names=FALSE) # AKA suppl_table_1.csv


##  ADDING THE SYNERGY RANKS OF DRUGS. THIS IS USED TO PLOT THE HEAT MAP ON THE WEB APP, 
##  WHERE DRUGS (ROWS AND COLUMNS) ARE RANKED BY TOTAL NUMBER OF SYNERGIES PER DRUG. 

nsyn.all.sym <- symmetrize(nsyn.all)
syn.per.drug <- symmetrize(nsyn.all.sym) %>% group_by(Drug1) %>% summarize(n.syn.tot=sum(n.syn, na.rm=TRUE))
syn.per.drug$Drug.num <- rank(-syn.per.drug$n.syn.tot, ties.method="first")
colnames(syn.per.drug) <- c("Drug1", "n.syn.tot1", "Drug.num1")
nsyn.all.sym <- left_join(nsyn.all.sym, syn.per.drug, by = "Drug1")
colnames(syn.per.drug) <- c("Drug2", "n.syn.tot2", "Drug.num2")
nsyn.all.sym <- left_join(nsyn.all.sym, syn.per.drug, by = "Drug2")


write.csv(nsyn.all.sym %>% dplyr::select_("Drug1","Drug2","Drug1.target","Drug2.target","n.syn","n.syn.score","Drug.num1","Drug.num2"),
          file.path(".", "combo_web", "combo_ranking_n.syn_score_web.csv"), row.names=FALSE)


###
###  PLOT A FEW OF THE TOP RESULTS ON A DOT PLOT DESIGNED TO REFLECT AMOUNT OF SYNERGY
###  IT SHOWS FOR EACH CELL LINE, THE COMBINATION VIABILITY WITH ERROR BAR (RED), 
###  THE EXPECTED VIABILITY UNDER INDENPENDENCE ASSUMPTION (BLACK) AND THE SINGLETS.
###

plot1combo2 <- function(d1, d2, title= "") {
	tmpplot <- filter(rawstt, Drug1==d1, Drug2==d2) %>% select(Drug1, Drug2, cell.line2, conc, viab, est.log.sing1, est.log.sing2, noise.total, noise.control.log)
	if (nrow(tmpplot) == 0) {tmp <- d1; d1 <- d2; d2 <- tmp;
		tmpplot <- filter(rawstt, Drug1==d1, Drug2==d2) %>% select(Drug1, Drug2, cell.line2, conc, viab, est.log.sing1, est.log.sing2, noise.total, noise.control.log)
	}
	tmpplot <- mutate(tmpplot, 
					est.sing1 = 10^-est.log.sing1, 
					est.sing2 = 10^-est.log.sing2, 
					expected=est.sing1*est.sing2, 
					combo.low = 10^-(-log10(viab)+2*noise.control.log), 
					combo.high = 10^-(-log10(viab)-2*noise.control.log)) %>% 
			select(Drug1, Drug2, cell.line2, conc, viab, est.sing1, est.sing2, expected, combo.low, combo.high)
	tmpplotm <- melt(tmpplot, id.vars = 1:4)
	ggplot(subset(tmpplotm, !(variable %in% c("expected", "combo.low", "combo.high"))), aes(cell.line2, value, colour=variable)) + geom_point(size=4) + facet_grid(conc ~ .) + 
			theme_bw() + theme(axis.text.x = element_text(angle=270, hjust=0)) + 
			xlab("") + ylab("Viability") + ggtitle(ifelse(title == "", sprintf("%s --- %s", d1, d2), title)) + 
			geom_line(data = subset(tmpplotm, variable %in% c("combo.low", "combo.high")), aes(group=cell.line2), colour="red") +
			geom_point(data = subset(tmpplotm, variable %in% c("expected")),     size=4, colour="black") +
			#geom_point(data = subset(tmpplotm, variable %in% c("viab")),         size=4, colour="red") +
			coord_cartesian(ylim = c(0, 1.25)) + #+ theme(legend.key.size=unit(3, "cm"))
			scale_colour_discrete(name="data", breaks=c("viab", "est.sing1", "est.sing2"), labels=c("Combo", as.character(d1), as.character(d2)))  
}

pdf(file.path(".", outdir, "synergy_dot_plots_combo_selection.pdf"), wi=11.5, he=8)
plot1combo2(d1="MK1775", d2="AZD7762") 
plot1combo2(d1="ABT263", d2="Wnti")
plot1combo2(d1="YM155", d2="lapatinib")
plot1combo2(d1="HIF-1i", d2="lapatinib")
plot1combo2(d1="STA4783", d2="XL147")
plot1combo2(d2="vatalanib/PTK787", d1="vincristine") 
dev.off()

###
###   THE SAME PLOTS ARE MADE INTERACTIVELY ON THE WEBSITE
###   WHEN THE HEAT MAP IS CLICKED. 
###   
###   HERE WE PREPARE A SMALLER VERSION OF THE FULL DATA (rawstt) FOR THE WEBSITE
###

raws <- filter(rawstt, !(Drug1 %in% "DMSO"), !(Drug2 %in% "DMSO")) %>% 
  select(Drug1, Drug2, cell.line2, conc, viab, noise.control.log, Nuclei, c.prop,
         est.log.sing1, est.log.sing2, sd.log.sing1, sd.log.sing2, zval, padj)

## Write numeric values with 3 digits. 
library(readr)
write.csv(format(as.data.frame(raws), digits=3), row.names=FALSE, file=file.path("combo_web", "combo_all_combos2.csv"))
#write_csv(as.data.frame(format(raws, digits=3)), path=file.path("combo_web", "combo_all_combos2.csv"))
