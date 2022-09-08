#--------------------------- Description ----------------------------#

# Function: This script selects core (e.g. European, African, Asian) subsamples based on PCA plot(s) of the study data with 1KG based on ellipse selection, generates zoom and threshold plots based on given thresholds, and generates a text file containing the list of selected individuals per core subsample.

# Contributors: Yunhan Chu (yunhanch@gmail.com)
# Contributors: Elizabeth Corfield, Tetyana Zayats

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript select-subsamples-on-pca-ellipse.R datalabel pcadata outprefix customfile
# Parameters: datalabel - a compact name of the study data to be used as a label
#                         in the titles and legends of the plots
#             pcadata - file path to the pca data
#             outprefix - prefix of the output plots
#             customfile - file customized with thresholds for the plots
# Example:    Rscript select-subsamples-on-pca-ellipse.R Norment_jun2015 norment_batch4_jun2015-1kg-yc-pca norment_batch4_jun2015-yc norment-jun2015-yc-pca-core-select-ellipse-custom.txt

#-------------------------- Input paramters -------------------------#
library(DescTools)
library(sp)

# Import arguments from command line
args <- commandArgs(TRUE)

# path of study data name
datalabel = args[1]
datatag = tolower(unlist(strsplit(datalabel, "_"))[1])

# path of the pca data file
pca = args[2]

# prefix of plot name
outprefix = args[3]

# custom file that defines how to deal with the core selection
customfile = args[4]

#----------------------------- Start code ---------------------------#

data=read.table(pca, header=F, strip.white=T, as.is=T)

num = length(data[,1])-1083

num_col=ncol(data)

data$color = c(rep("red", num), rep("black", 61), rep("lightblue", 85), rep("blue", 97), rep("aquamarine", 99), rep("yellow", 60), rep("green", 93), rep("purple", 89), rep("orange", 14), rep("gray", 89), rep("darkolivegreen", 91), rep("magenta", 64), rep("darkblue", 55), rep("orchid", 98), rep("cyan3", 88))

data$label = c(rep(datatag, num), rep("ASW", 61), rep("CEU", 85), rep("CHB", 97), rep("CHS", 99), rep("CLM", 60), rep("FIN", 93), rep("GBR", 89), rep("IBS", 14), rep("JPT", 89), rep("LWK", 91), rep("MXL", 64), rep("PUR", 55), rep("TSI", 98), rep("YRI", 88))

data_zoom_list <- list()
draw_ellipse_list <- list()
legend_position_list <- list()

######################## Here to customize plots #######################

custom <- readLines(customfile)
custom <- custom[trimws(custom) != ""]
custom <- custom[!startsWith(custom,'#')]

if (length(custom) %% 2 > 0 && length(custom) %% 3 > 0) {
    stop("please define zoom/draw thresholds and legend positions for all subsamples")
}

tag_list <- unique(sub("_.*", "", custom))

if (length(tag_list) > 0) {
    for (j in 1:num_col) {
        custom <- gsub(paste0("PC",j), paste0("data$V",j+2), custom)
    }
    for (i in 1:length(custom)) {
        line = gsub("^\\s+|\\s+$", "", sub(".*:","",custom[i]))
        if (grepl("zoom_threshold", custom[i], fixed = TRUE)==TRUE) {
            zoom_text=paste0("data_zoom <- data[", line ,", ]")
            eval(parse(text=zoom_text))
            data_zoom_list <- append(data_zoom_list,list(data_zoom))
        }else if (grepl("draw_ellipse", custom[i], fixed = TRUE)==TRUE) {
            draw_ellipse = line
            draw_ellipse_list <- append(draw_ellipse_list,draw_ellipse)
        }else if (grepl("legend_position", custom[i], fixed = TRUE)==TRUE) {
            legend_position = line
            legend_position_list <- append(legend_position_list,legend_position)
        }
    }
}

########################################################################

if (length(tag_list) > 0) {
    for (i in 1:length(tag_list)) {
        tag <- tag_list[i]
        data_zoom <- data_zoom_list[[i]]

        centerx=0
        centery=0
        firstradius=0
        secondradius=0
        rotangle=0
        if (length(draw_ellipse_list) > 0) {
            draw_ellipse <- draw_ellipse_list[[i]]
            centerx = as.numeric(trimws(sub(".*=","",unlist(strsplit(draw_ellipse, ","))[1])))
            centery = as.numeric(trimws(sub(".*=","",unlist(strsplit(draw_ellipse, ","))[2])))
            firstradius = as.numeric(trimws(sub(".*=","",unlist(strsplit(draw_ellipse, ","))[3])))/2
            secondradius = as.numeric(trimws(sub(".*=","",unlist(strsplit(draw_ellipse, ","))[4])))/2
            angledegree = trimws(sub(".*=","",unlist(strsplit(draw_ellipse, ","))[5]))
            rotangle = as.numeric(angledegree)*pi/180
        }else {
            centerx = round(mean(data_zoom[,3]),4)
            centery = round(mean(data_zoom[,4]),4)
            var = var(data.frame(data_zoom[,3], data_zoom[,4]))
            eig = eigen(var)
            eig.val = sqrt(eig$values)
            eig.vec = eig$vectors
            firstradius = round(eig.val[1]*2,4)
            secondradius = round(eig.val[2]*2,4)
            rotangle = round(acos(eig.vec[1,1]),4)
            angledegree = round(rotangle*180/pi,2)
        }
        minx=min(data_zoom[,3])
        if (minx > centerx-firstradius) {
            minx = centerx-firstradius
        }
        maxx=max(data_zoom[,3])
        if (maxx < centerx+firstradius) {
            maxx = centerx+firstradius
        }
        miny=min(data_zoom[,4])
        if (miny > centery-firstradius) {
            miny = centery-firstradius
        }
        maxy=max(data_zoom[,4])
        if (maxy < centery+firstradius) {
            maxy = centery+firstradius
        }
        subtext=paste0("[",format(centerx,scientific = FALSE),", ",format(centery,scientific = FALSE),", ",format(firstradius*2,scientific = FALSE),", ",format(secondradius*2,scientific = FALSE),", ",format(angledegree,scientific = FALSE),"]")
        legend_position <- legend_position_list[[i]]

        png(width=900,height=500,file=paste(outprefix,'-first-pca-plot-pc1-pc2-zoom-',tag,'.png',sep=''))
        par(mfrow=c(1,2))
        plot(data_zoom[,3],data_zoom[,4],pch=20,main=paste0(paste0(toupper(substring(datalabel,1,1)),substring(datalabel,2))," + 1KG zoomed ",toupper(tag),", PC1 vs PC2"),xlim=c(minx,maxx),ylim=c(miny,maxy),col=data_zoom$color,xlab="PC1",ylab="PC2",sub=subtext)
        ell=DrawEllipse(x=centerx, y=centery, radius.x=firstradius, radius.y=secondradius, rot=rotangle, nv=200, border="red", col=NA, lwd=2)
        data$pointin <- point.in.polygon(data[,3], data[,4], ell$x, ell$y)
        data_threshold <- data[data$pointin==1,]
        data_threshold_study <- data_threshold[data_threshold$label==datatag, ]
        write.table(data.frame(data_threshold_study$V1, data_threshold_study$V2), paste(outprefix,'-core-subsample-',tag,'.txt',sep=''), quote=F, row.names=F, col.names=F, sep=' ')
        df <- data.frame(table(data_threshold$label))
        df <- df[match(unique(data_threshold$label),df$Var1), ]
        points(x=centerx, y=centery, pch=3, col='black')
        legend(legend_position, title=paste0(toupper(tag),' subsample'), legend=paste0(df$Var1,' (',df$Freq,')'), fill=unique(data_threshold$color))

        data_zoom2=rbind(data_zoom[data_zoom$label!=datatag,],data_zoom[data_zoom$label==datatag,])
        plot(data_zoom2[,3],data_zoom2[,4],pch=20,main=paste0(paste0(toupper(substring(datalabel,1,1)),substring(datalabel,2))," + 1KG zoomed ",toupper(tag),", PC1 vs PC2"),xlim=c(minx,maxx),ylim=c(miny,maxy),col=data_zoom2$color,xlab="PC1",ylab="PC2",sub=subtext)
        ell=DrawEllipse(x=centerx, y=centery, radius.x=firstradius, radius.y=secondradius, rot=rotangle, nv=200, border="red", col=NA, lwd=2)
        points(x=centerx, y=centery, pch=3, col='black')
        legend(legend_position, title=paste0(toupper(tag),' subsample'), legend=paste0(df$Var1,' (',df$Freq,')'), fill=unique(data_threshold$color))
        invisible(dev.off())

        png(width=800,height=600,paste(outprefix,'-first-pca-plots-pc1-pc7-threshold-',tag,'.png',sep=''))
        par(mfrow=c(2,3))
        plot(data_threshold[,3],data_threshold[,4],pch=20,main=paste0(paste0(toupper(substring(unlist(strsplit(datalabel, "_"))[1],1,1)),substring(unlist(strsplit(datalabel, "_"))[1],2))," + 1KG threshold ",toupper(tag),", PC1 vs PC2"),col=data_threshold$color,xlab="PC1",ylab="PC2")
        legend(legend_position, legend=paste0(df$Var1,' (',df$Freq,')'), fill=unique(data_threshold$color))
        plot(data_threshold[,4],data_threshold[,5],pch=20,main="PC2 vs PC3",col=data_threshold$color,xlab="PC2",ylab="PC3")
        plot(data_threshold[,5],data_threshold[,6],pch=20,main="PC3 vs PC4",col=data_threshold$color,xlab="PC3",ylab="PC4")
        plot(data_threshold[,6],data_threshold[,7],pch=20,main="PC4 vs PC5",col=data_threshold$color,xlab="PC4",ylab="PC5")
        plot(data_threshold[,7],data_threshold[,8],pch=20,main="PC5 vs PC6",col=data_threshold$color,xlab="PC5",ylab="PC6")
        plot(data_threshold[,8],data_threshold[,9],pch=20,main="PC6 vs PC7",col=data_threshold$color,xlab="PC6",ylab="PC7")
        invisible(dev.off())
    }
}
