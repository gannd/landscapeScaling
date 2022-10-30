#' Generate multi-dimensional grid points
#' 
#' @param parts integer indicating the number of partitions (precision of class-label names)
#' @param richness the number of classes (categories in categorical data)
#' 
#' @return A data frame with all possible combinations of percentages (rows) for the requested number of partitions and richness (number of columns = richness).
#' 
#' @importFrom compositions ccomp
#' @importFrom partitions compositions
#' 
#' @export
#'
#' @examples
#' mdgp_generate(parts=4,richness=3)

mdgp_generate <- function(parts=2,richness=2){
  
  # generate grid points
  suppressWarnings(grid_points <- compositions::ccomp(t(partitions::compositions(n=parts, m=richness, include.zero=TRUE)), total=100))	
  rownames(grid_points) <- c(1:length(grid_points[,1]))
  grid_points <- as.data.frame(grid_points[,1:richness])
  print(paste('number of grid points: ',as.character(length(grid_points[,1])),sep=''))
  
  return(grid_points)
}