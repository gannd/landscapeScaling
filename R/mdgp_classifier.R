#' Classify samples to multi-dimensional grid points and calculate percent information retention

#' @param samples data frame object generated with function (...)
#' @param grid_points spatial raster object with categorical data (factor)
#' @param i minimum percentage of grid cell covered to include in scaling; set grid point classifier function flag 0 = optimized, 1 = brute force
#'
#' @returns data frame with two columns: class and information retention.
#' 
#' @noRd
#' @keywords internal

mdgp_classifier <- function(samples,grid_points,i){
  
  smpClsRes <- t(apply(samples, 1, function(x) mdgp_classify_sample(sample=x,grid_points=grid_points,i=i)))
  samples$cls <-  unlist(lapply(smpClsRes, "[[", 1))
  samples$prc_inf_agr <-  unlist(lapply(smpClsRes, "[[", 2))
  suppressWarnings(samples$x_y <- rownames(samples))
  
  return (samples)
}
# -----
#' Classify sample to multi-dimensional grid point

#' @param sample vector or list
#' @param grid_points spatial raster object with categorical data (factor)
#' @param i minimum percentage of grid cell covered to include in scaling
#' 
#' @returns data frame with two columns: class and information retention
#' 
#' @noRd
#' @keywords internal

mdgp_classify_sample <- function(sample,grid_points,i){
  
  # subset sample
  s <- t(as.data.frame(sample))
  
  # optimized subset of grid points (remove empty grid points)
  if (i == 0){
    # index of variables with 0 percent
    idxZ <- which(sample == 0)

    # index for maximum %
    idxM <- which.max(sample)

    gpC <- as.data.frame(grid_points[rowSums(as.data.frame(grid_points[,idxZ])) == 0 & (grid_points[,idxM] != 0),])
  } else { gpC <- grid_points }

  # calculate percent agreement of retained information 	
  prcAgrGrdSmp <- as.data.frame(round(percent_agreement(sample=s,grid_points=gpC),3))
  names(prcAgrGrdSmp) <- rownames(gpC)
  aggMaxIdx <- names(which.max(prcAgrGrdSmp))
  
  if (length(aggMaxIdx) > 1){
    aggMaxIdx <- unlist(aggMaxIdx, function(x) random_selelect_ties(x))
  }
  aggMax <- max(prcAgrGrdSmp)
  
  return(list(aggMaxIdx,aggMax))
}
# -----
#' Random selection of tied grid points

#' @param x data frame
#' 
#' @returns sample assignment to randomly selected tied information retention of grid points
#' 
#' @noRd
#' @keywords internal

random_selelect_ties <- function(x) {
  
  if (length(x) <= 1) {
    return(x)
  } else {
    return(sample(x,1))
  }
}
# -----
#' Sum of pairwise percent minimum agreement (retained information)

#' @param sample sample for which information retention is calculated
#' @param grid_points multi-dimensional grid points
#' 
#' @returns sum of minimum retained percentages
#'  
#' @noRd
#' @keywords internal

percent_agreement <- function(sample,grid_points){
  
  # sum of minimum retained percentages 	
  inf_ret <- outer(1:nrow(sample), 1:nrow(grid_points), Vectorize(function(i, j) sum(pmin(sample[i, ],grid_points[j, ]))))
  
  return(inf_ret)
}
# -----
#' Frequency per grid point class
#' 
#' @param class_sample sample for which information retention is calculated
#' @param grid_points grid points
#' 
#' @returns grid point index frequency
#'  
#' @noRd
#' @keywords internal

cls_freq <- function(grid_points,class_samples){
  
  # tabulate class representativness
  frq <- as.data.frame(table(class_samples$cls))
  
  # create grid point index data frame -- in case grid point classes do not have samples assigned to them 
  grdIdx <- as.data.frame(c(1:length(grid_points[,1])))
  names(grdIdx) <- 'grdIdx'
  
  # generate frequency distribution for grid point index
  grdIdxFrq <- merge(grdIdx,frq, by.x='grdIdx', by.y='Var1', all.x=TRUE) 
  grdIdxFrq$Freq[is.na(grdIdxFrq$Freq)] <- 0
  grdIdxFrq$grdPntPrc <- grdIdxFrq$Freq *100/sum(grdIdxFrq$Freq)
  
  return(grdIdxFrq)
}
# -----
#' Generate class label
#' 
#' @param df data frame row with percent abundance and original class column names
#' 
#' @returns class name
#'  
#' @noRd
#' @keywords internal

class_label <- function(df){
  
  # generate label data frame
  df.lbl <- as.data.frame(df)
  df.lbl$nme <- rownames(df.lbl)
  df.sub <- df.lbl[df.lbl$df > 0,]
  df.lbl <- df.sub[order(df.sub$df, decreasing=TRUE),]
  df.lbl$class_name <- paste(df.lbl$nme,df.lbl$df,sep='')
  class_name <- paste(df.lbl$class_name, collapse = '_x_')
  
  return(class_name)
}
# EOF
