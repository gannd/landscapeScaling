#' Generate relative class abundances of original (finer resolution) grid cells for scaled (coarser resolution) grid cells

#' @param x SpatRaster object with categorical data (factor)
#' @param class_field field name in the attribute table of the raster to be used as class names
#' @param scale_factor ratio of lower (scaled) resolution to higher (original) raster resolution (resolution of lower resolution divided by resolution of higher resolution) 
#' @param verbose bolean; if TRUE progress will be printed in console; default = FALSE
#'
#' @return A data frame with relative abundance of classes. The first two columns are x and y coordinates; all other columns are counts of cells for each class.
#' 
#' @export
#' 
#' @examples
#' # load categorical raster
#' r <- terra::rast(system.file("extdata/nlm_mid_geom_r3_sa0.tif", package = "landscapeScaling"))
#' 
#' # subset the raster
#' r_sub <- terra::crop(r,terra::ext(0,300,0,300))
#' 
#' # generate relative abundance of original classes for a scaled grid with scale factor of 15
#' rel_abund <- relative_abundance_scaled_grid(r_sub,class_field='cover',scale_factor=15)
#' 
#' head(rel_abund)

relative_abundance_scaled_grid <- function(x,class_field,scale_factor,verbose=FALSE){
  
  # generate grid points
  refPntsXY <- scale_grid(x,scale_factor)
  
  # x and y resolution of original raster
  res_x <- terra::res(x)[1]
  res_y <- terra::res(x)[2]
  
  # number of original raster classes
  richness <- length(terra::cats(x)[[1]]$value)
  
  # initiate data frame to collect relative abundance for low resolution grid cell coordinates
  relAbn <- matrix(nrow=richness, ncol=length(refPntsXY[,1]))
  
  for(pnt in 1:(length(refPntsXY[,1]))){
    if (verbose == TRUE){
      print(paste0(pnt,' out of ',length(refPntsXY[,1])))
    }
    
    # initiate new data frame for current sample
    curSmp <- terra::cats(x)[[1]]

    # calculate row / column start from current sample cell
    cellCur <- refPntsXY[pnt,]

    # extent for current sample
    ext <- terra::ext(cellCur$x,cellCur$x+scale_factor*res_x,cellCur$y,cellCur$y+scale_factor*res_y)

    # extract sample data value block
    vB <- terra::extract(x, ext)

    # get frequency distribution of value block and convert to data frame
    vBFreqDF <- as.data.frame(table(vB))

    if (length(vBFreqDF[,1]) < 1){
      # if no classes are present (all NA) replace current sample vector in matrix with zeros
      relAbn[,pnt] <- rep(0,richness)
    } else {
      # join sample data frequencies to data frame
      suppressWarnings(curSmp <- merge(curSmp, vBFreqDF, by=class_field, all.x=TRUE))

      # set absent classes (NA) to 0
      curSmp[is.na(curSmp)] <- 0

      # replace current sample vector in matrix
      relAbn[,pnt] <- curSmp[,3]
    }
  }
  # rotate data matrix
  relAbn <- as.data.frame(t(relAbn))
  
  # calculate percentage compositions
  suppressWarnings(datCmp <- compositions::ccomp(relAbn, total=100))
  
  # add column names
  colnames(datCmp) <- unlist(terra::cats(x)[[1]][class_field])

  # add relative abundances to x y coordinates
  datCmp <- cbind(refPntsXY,datCmp)

  return(datCmp)
}
