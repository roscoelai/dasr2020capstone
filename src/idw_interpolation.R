# idw_interpolation.R

idw_interpolation <- function(points, points_label,
                              polys, polys_label,
                              ordinal = 2) {
  #' Inverse-distance-weighted (IDW) Interpolation
  #' 
  #' @description
  #' Calculate the inverse-distance-weighted (IDW) averages of the values of a 
  #' given set of points to the centroids of a given set of polygons.
  #' 
  #' The ordinal determines the amount of weight given to inverse-distances. 
  #' An ordinal of 0 will return the same value (the arithmetic mean) to all 
  #' centroids. A large ordinal will heavily penalize points that are far away. 
  #' A negative ordinal will result in distance-weighted interpolation - please 
  #' don't do that.
  #' 
  #' @param points sf object containing point features.
  #' @param polys sf object containing polygon features.
  #' @param points_label Column name of the labels in points.
  #' @param polys_label Column name of the labels in polys.
  #' @param ordinal Determines the amount of weight given to inverse-distances.
  #' @return Interpolated values for each polygon.
  
  if (ordinal < 0) {
    stop("You are highly encouraged to use a non-negative ordinal.")
  }
  
  # weights: (nrow(polys) x nrow(points))
  weights = polys %>% 
    sf::st_centroid() %>% 
    sf::st_distance(points) %>% 
    units::set_units(km) %>% 
    { 1 / (.^ordinal) }
  
  # values: (nrow(points) x ncol(values))
  values = points %>% 
    as.data.frame() %>% 
    dplyr::select(-{{ points_label }}, -geometry) %>% 
    as.matrix()
  
  # result: (nrow(polys) x ncol(values))
  result = tibble::as_tibble(weights %*% values / rowSums(weights))
  
  polys %>% 
    tibble::as_tibble() %>% 
    dplyr::select({{ polys_label }}) %>% 
    dplyr::bind_cols(result)
}