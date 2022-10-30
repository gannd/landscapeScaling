#' Information retention summary statistics

#' @param scaling_result data frame with scaling results returned by function mdgp_scale
#' @param class_name_field column name in the scaling results data frame that contains the scaled class names
#' 
#' @return A list with two data frames. First data frame contains class-specific cell class name (class_name), class frequencies (freq), class raster id (class_id), class proportion (prop), information retention mean (inf_retention_mn) and standard deviations (inf_retention_sd). The second data frame contains the mean (mean) and standard deviation (sd) for the scaled landscape across all classes.
#' 
#' @importFrom stats aggregate
#' @importFrom stats sd
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
#' # generate relative abundance for the scaled grid
#' rel_abund <- relative_abundance_scaled_grid(r_sub,class_field='cover',scale_factor=15)
#' 
#' head(rel_abund)
#' 
#' # classify relative abundance samples to multi-dimensional grid points
#' mdgp_result <- mdgp_scale(rel_abund,parts=3,rpr_threshold=10,monotypic_threshold=90)
#' 
#' head(mdgp_result)
#' 
#' # generate class-specific and landscape scale information retention statistics
#' infRetStats <- info_retention_stats(mdgp_result,'class_name')
#' 
#' print(infRetStats)

info_retention_stats <- function(scaling_result,class_name_field){
  
  rslt <- as.data.frame(base::table(scaling_result[class_name_field]))
  rslt <- rslt[rslt$Freq != 0,]
  rslt$cls <- rownames(rslt)
  rslt$prp <- rslt$Freq/sum(rslt$Freq)
  infRetMn <- round(as.data.frame(stats::aggregate(scaling_result$prc_inf_agr, scaling_result[class_name_field], mean))[,2],3)
  infRetSD <- round(as.data.frame(stats::aggregate(scaling_result$prc_inf_agr, scaling_result[class_name_field], sd))[,2],3)
  
  rslt <- cbind(rslt,infRetMn,stringsAsFactors = FALSE)
  rslt <- cbind(rslt,infRetSD,stringsAsFactors = FALSE)
  
  names(rslt) <- c(class_name_field,'freq','class_id','prop','inf_retention_mn','inf_retention_sd')
  
  # calculate landscape scale mean and standard deviation of information retention 
  information_retention_landscape <- data.frame(mean=numeric(1),sd=numeric(1))
  rownames(information_retention_landscape) <- 'information_retention_landscape'
  information_retention_landscape[1,] <- c(mean=round(base::mean(scaling_result$prc_inf_agr),3),sd=round(stats::sd(scaling_result$prc_inf_agr),3))
  
  return(list(rslt,information_retention_landscape))
}
