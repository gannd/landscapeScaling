#' Classify relative abundance samples to multi-dimensional grid points and calculate percent information retention for each scaled grid cell

#' @param x data frame with relative abundance of classes in columns generated with function relative_abundance_scaled_grid()
#' @param parts integer that sets the class label precision of scaled classes. OPTIONS: 1 = 100%, 2 = 50%, 3 = 33.3%, 4 = 25%, 5 = 20%  
#' @param rpr_threshold integer setting the representativeness threshold, the  minimum percentage of a mixed class in the scaled landscape to be retained in the classification scheme
#' @param monotypic_threshold integer that sets the minimum percentage of a class to be considered monotypic and therefore retained in the scaled classification scheme 
#' @param ir_threshold integer that sets the minimum cell-level information retention threshold in percent before a class gets assigned to class 'OTHER'; default = 1
#' @param verbose bolean; if TRUE progress will be printed in console; default = FALSE
#' 
#' @return A data frame with first column containing the scaled category IDs followed by the original class columns with relative class abundance in percent. The last three columns are x_y = concatenated x and y coordinates, prc_inf_agr = percent information retained for each scaled grid cell, and class_name = the class labels of the scaled classes
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
#' # Ex. 1: classify relative abundance samples to multi-dimensional grid points 
#' # class-label precision = 33.3% (parts=3), 
#' # minimum representativeness = 10%, monotypic threshold 90%, information retention threshold 0% (default) 
#' mdgp_result <- mdgp_scale(rel_abund,parts=3,rpr_threshold=10,monotypic_threshold=90)
#' 
#' head(mdgp_result)
#'
#' 
#' # Ex.2: classify relative abundance samples to multi-dimensional grid points with information retention threshold at 50%
#' mdgp_result <- mdgp_scale(rel_abund,parts=3,rpr_threshold=10,monotypic_threshold=90,ir_threshold=50)
#' 
#' head(mdgp_result)
#' 
#' # print the class distribution class frequencies
#' table(mdgp_result$class_name)

mdgp_scale <- function(x,parts,rpr_threshold,monotypic_threshold,ir_threshold=1,verbose=FALSE){
  
  print(paste0('number of cells: ',cellCount <- length(x[,1])))
  
  # prepare data frame for scaling: merge x and y to x_y as sample identifier and remove original columns
  rownames(x) <- paste(x$x,x$y,sep='_')
  x <- x[,3:ncol(x)] 
 
  # number of original classes
	richness <- ncol(x)

	# duplicate data frame 
	smpPrc <- as.data.frame(x)
	
	# generate grid points
	gp <- mdgp_generate(parts,richness)
	names(gp) <- names(x)
	# -----------------------------------------------------------------------------------------------------------------
	# initiate classified sample data frame: subset all monotypic samples
	
	smpClsFnl <- smpPrc[apply(smpPrc, 1, function(x) any(x >= monotypic_threshold)), ]
	if (length(smpClsFnl[,1]) < 1){
	  smpClsFnl$x_y <- character(0)
		smpClsFnl$cls <- character(0)	
		smpClsFnl$prc_inf_agr <- numeric(0)
		gpIDFnl <- c()
	} else {
		# assign class based on grid point row
	  smpClsFnl$x_y <- rownames(smpClsFnl)
		smpClsFnl$cls <- apply(smpClsFnl[,1:ncol(smpPrc)], 1, function(x) rownames(gp)[gp[names(which(x == max(x)))] >= monotypic_threshold]) 
		smpClsFnl$prc_inf_agr <- apply(smpClsFnl[,1:ncol(smpPrc)], 1, function(x) max(x))	
		gpIDFnl <- unique(smpClsFnl$cls)
	}
	if (verbose == TRUE){
	  print(smpClsFnl)
	}
	# -----------------------------------------------------------------------------------------------------------------
	## classify non-monotypic samples
	
	# subset non-monotypic samples
	smpPrc <- smpPrc[apply(smpPrc, MARGIN = 1, function(x) !any(x >= monotypic_threshold)), ]	
	
	# set grid point classifier function flag to optimized {0 = optimized, 1 = brute force, 2 = stop}
	i <- 0
	
	# filter: iterative removal of grid points of smallest partition until smallest partition reaches landscape threshold
	while (i < 2){

		# classify samples to grid points
		smpCls <- mdgp_classifier(samples=smpPrc, grid_points=gp, i=i)
				
		# append classified non-monotypic samples back to final data frame 
		smpClsFnl <- rbind(smpClsFnl,smpCls)
		
		# check for classes below representativeness threshold
		grdIdxFrq <- cls_freq(gp,smpClsFnl)
		if (verbose == TRUE){
		  print(paste('classes below threshold', length(grdIdxFrq$Freq[(grdIdxFrq$grdPntPrc != 0) & (grdIdxFrq$grdPntPrc < rpr_threshold)]), sep=': '))
		  print(paste('classes above threshold', length(grdIdxFrq$Freq[(grdIdxFrq$grdPntPrc != 0) & (grdIdxFrq$grdPntPrc >= rpr_threshold)]), sep=': '))
		  print(paste('cells to reclassify', sum(grdIdxFrq$Freq[(grdIdxFrq$grdPntPrc != 0) & (grdIdxFrq$grdPntPrc < rpr_threshold)]), sep=': '))
		}
		# -----------------------------------------------------------------------------------------------------------------
		# remove grid points that are zero and smallest partition not equal to zero
		
		if (any (grdIdxFrq$grdPntPrc[grdIdxFrq$grdPntPrc != 0 & !grdIdxFrq$grdIdx %in% gpIDFnl] < rpr_threshold)){
			
		  # reset grid point classifier function to bf
			i <- 1
			
			# determine grid points to be removed in current cycle: all 0, minimum percentage that is not in monotypic list (gpIDFnl)
			gpRmCnd <- grdIdxFrq[!grdIdxFrq$grdIdx %in% as.numeric(gpIDFnl),]
			gpRm <- as.integer(c(grdIdxFrq$grdIdx[grdIdxFrq$grdPntPrc == 0],gpRmCnd$grdIdx[gpRmCnd$grdPntPrc == min(gpRmCnd$grdPntPrc[gpRmCnd$grdPntPrc !=0])]))
			gp <- gp[!(rownames(gp) %in% gpRm),]
			print(paste('number of grid points remaining',length(gp[,1]),sep=': '))
			
			# subset samples from classified data frame for classes below threshold for re-classification
			smpPrc <- smpClsFnl[smpClsFnl$cls %in% as.integer(grdIdxFrq$grdIdx[grdIdxFrq$grdPntPrc == min(grdIdxFrq$grdPntPrc[grdIdxFrq$grdPntPrc !=0 & !grdIdxFrq$grdIdx %in% gpIDFnl])]),][,1:richness]
			
			# remove samples from classified data frame 
			smpClsFnl <- smpClsFnl[!smpClsFnl$cls %in% as.integer(grdIdxFrq$grdIdx[grdIdxFrq$grdPntPrc == min(grdIdxFrq$grdPntPrc[grdIdxFrq$grdPntPrc !=0 & !grdIdxFrq$grdIdx %in% gpIDFnl])]),]
			
		} else { i <- 2}
	}
	
	# reclassify samples below ir_threshold to 'ZZ_OTHER'
	smpClsFnl$cls[smpClsFnl$prc_inf_agr < ir_threshold] <- max(as.numeric(smpClsFnl$cls)) + 1
	
	# check length samples in == classified samples out
	if (length(smpClsFnl[,1]) != nrow(x)){ print('error in grid point scaling - not all grid cells were classified') }
	else {
		# generate final grid point class names
		names(gp) <- names(x)
		grdPntsFnl <- as.data.frame(apply(round(gp,0), 1, function(x) class_label(x)))
		names(grdPntsFnl) <- 'class_name'
		
		# add other class
		o <- data.frame(class_name = 'ZZZ_OTHER') 
		grdPntsFnl <- rbind(grdPntsFnl,o)
		
		# merge classified samples with class names
		smpClsFnl <- merge(smpClsFnl,grdPntsFnl, by.x='cls', by.y='row.names', sort=FALSE)
		rownames(smpClsFnl) <- smpClsFnl$x_y
		smpClsFnl <- data.frame(lapply(smpClsFnl, function(x) if(is.numeric(x)) round(x, 3) else x)) 
		
		# set information retention of the 'ZZZ_OTHER' class to 0
		smpClsFnl$prc_inf_agr[smpClsFnl$class_name == 'ZZZ_OTHER'] <- 0
		
		return(smpClsFnl)		
	}	
}
