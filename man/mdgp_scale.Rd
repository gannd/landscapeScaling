% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mdgp_scale.R
\name{mdgp_scale}
\alias{mdgp_scale}
\title{Classify relative abundance samples to multi-dimensional grid points and calculate percent information retention for each scaled grid cell}
\usage{
mdgp_scale(
  x,
  parts,
  rpr_threshold,
  monotypic_threshold,
  ir_threshold = 1,
  verbose = FALSE
)
}
\arguments{
\item{x}{data frame with relative abundance of classes in columns generated with function relative_abundance_scaled_grid()}

\item{parts}{integer that sets the class label precision of scaled classes. OPTIONS: 1 = 100\%, 2 = 50\%, 3 = 33.3\%, 4 = 25\%, 5 = 20\%}

\item{rpr_threshold}{integer setting the representativeness threshold, the  minimum percentage of a mixed class in the scaled landscape to be retained in the classification scheme}

\item{monotypic_threshold}{integer that sets the minimum percentage of a class to be considered monotypic and therefore retained in the scaled classification scheme}

\item{ir_threshold}{integer that sets the minimum cell-level information retention threshold in percent before a class gets assigned to class 'OTHER'; default = 1}

\item{verbose}{bolean; if TRUE progress will be printed in console; default = FALSE}
}
\value{
A data frame with first column containing the scaled category IDs followed by the original class columns with relative class abundance in percent. The last three columns are x_y = concatenated x and y coordinates, prc_inf_agr = percent information retained for each scaled grid cell, and class_name = the class labels of the scaled classes
}
\description{
Classify relative abundance samples to multi-dimensional grid points and calculate percent information retention for each scaled grid cell
}
\examples{
# load categorical raster
r <- terra::rast(system.file("extdata/nlm_mid_geom_r3_sa0.tif", package = "landscapeScaling"))

# subset the raster to the lower 300 by 300 pixels
r_sub <- terra::crop(r,terra::ext(0,300,0,300))

# generate relative abundance for the scaled grid
rel_abund <- relative_abundance_scaled_grid(r_sub,class_field='cover',scale_factor=15)

head(rel_abund)

# Ex. 1: classify relative abundance samples to multi-dimensional grid points 
# class-label precision = 33.3\% (parts=3), 
# minimum representativeness = 10\%, monotypic threshold 90\%, information retention threshold 0\% (default) 
mdgp_result <- mdgp_scale(rel_abund,parts=3,rpr_threshold=10,monotypic_threshold=90)

head(mdgp_result)


# Ex.2: classify relative abundance samples to multi-dimensional grid points with information retention threshold at 50\%
mdgp_result <- mdgp_scale(rel_abund,parts=3,rpr_threshold=10,monotypic_threshold=90,ir_threshold=50)

head(mdgp_result)

# print the class distribution class frequencies
table(mdgp_result$class_name)
}
