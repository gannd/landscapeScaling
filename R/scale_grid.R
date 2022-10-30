#' Generate scaled grid cell points

#' @param x SpatRaster object with categorical data (factor)
#' @param scale_factor ratio of lower (scaled) resolution to higher (original) raster resolution (resolution of lower resolution divided by resolution of higher resolution)
#' 
#' @return A data frame with x and y coordinates of the lower left corner of grid cells of a scaled grid
#' 
#' @export
#' 
#' @examples 
#' # load categorical raster
#' r <- terra::rast(system.file("extdata/nlm_mid_geom_r3_sa0.tif", package = "landscapeScaling"))
#' 
#' # subset the raster to the lower 300 by 300 pixels
#' r_sub <- terra::crop(r,terra::ext(0,300,0,300))
#' 
#' # generate lower left corner grid points of the scaled grid cells
#' LL_pnts <- scale_grid(r_sub,scale_factor=15)
#'
#' # print the first rows of the point coordinates data frame
#' head(LL_pnts)
#' 
#' # plot the subset raster and the scaled grid corner points
#' # three class color scheme
#' clr <- c('#332288','#44AA99','#DDCC77')
#' terra::plot(r_sub,col=clr,mar=c(1.5,1.5,1,1))
#' terra::plot(terra::vect(LL_pnts,geom=c("x","y")),pch=3,col='#EEEEEE',add=TRUE)

scale_grid <- function(x,scale_factor){
  
  # get spatial extent for raster
  mapRefSclExt <- terra::ext(x)
  
  # generate lower left corner coordinates for scaled raster grid points
  xLst <- seq(mapRefSclExt$xmin,mapRefSclExt$xmax-scale_factor*terra::res(x)[1],scale_factor)
  yLst <- seq(mapRefSclExt$ymin,mapRefSclExt$ymax-scale_factor*terra::res(x)[2],scale_factor)
  pntDF <- expand.grid(xLst,yLst)
  names(pntDF) <- c('x','y')
  
  return(pntDF)
}
