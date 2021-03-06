# Ordinary kriging of the meuse zinc data with constant ~1
# Universial kriging of the meuse zinc data, using sqrt(dist) as covariate.

# Initializing binding tool function
tool_exec <- function(in_params, out_params)
{
  # loading packages  
  if (!requireNamespace("sp", quietly = T))
    install.packages("sp")
  if (!requireNamespace("gstat",quietly = T))
    install.packages("gstat")
  if (!requireNamespace("raster",quietly = T))
    install.packages("raster")
  
  require(sp)
  require(gstat)
  require(raster)
  
  message("initializing")
  # defining variables
  input_feature = in_params[[1]]
  predict_location = in_params[[2]]
  dep_variable = in_params[[3]]
  log_var = in_params[[4]]
  covariate_var = in_params[[5]]
  vgm_mod = in_params[[6]]
  
  output_feature1 = out_params[[1]]
  output_feature2 = out_params[[2]]
  
  #exporting datasets
  d = arc.open(input_feature)
  dat = arc.select(d,names(d@fields))
  dat.2 = arc.data2sp(dat)
  
  message("Creating model formula")
  if (!is.null(covariate_var))
  {  
    if (log_var == FALSE)
    {
      model_kr = paste(dep_variable, "~sqrt(",covariate_var,")")
      
    }
    else
    {
      model_kr = paste(paste ("log(",dep_variable,")"),paste("~sqrt(",covariate_var,")"))
    }
    message(paste0("formula =",model_kr ))
  }
  else 
  {
    if (log_var == FALSE)
    {
      model_kr = paste(dep_variable, "~1")
      message("formula =",model_kr)
    }
    else
    {
      model_kr = paste(paste ("log(",dep_variable,")"),paste("~1"))
      message("formula = log(",dep_variable,")~1")
    }
  }
  
  model_kr.f = as.formula(model_kr)
  
  message("Input vgm_model = ",vgm_mod)
  
  message("creating variogram...")
  out_varianc = variogram(model_kr.f,dat.2)
  vario.fit = fit.variogram(out_varianc,eval(parse(text= vgm_mod)))
  
  print(vario.fit)
  
  message("Predicting...")
  d.loc <- arc.open(predict_location)
  data.loc = arc.select(d.loc, names(d.loc@fields))
  data.loc.1 = arc.data2sp(data.loc)
  gridded(data.loc.1)=T
  
  #### Write Output ####
  
  
  message("....kriging now....")
  out_krig = krige(model_kr.f,dat.2, data.loc.1, vario.fit)
  message(class(out_krig))
  gridded(out_krig)=T
  out_krig1 = out_krig[1]
  
  gridded(out_krig)=F
  out_krig2 = out_krig[2]
  
  message("...write output...")
  arc.write(output_feature1,out_krig1, shape_info = d@shapeinfo)
  
  if (!is.null(output_feature2))
  {
    pdf(output_feature2)
    print(plot(out_varianc,vario.fit,main = "Variogram with fitted Model",cex.main = 1.25))
    gridded(out_krig)=TRUE
    print(spplot(out_krig))
    gridded(out_krig1)=T
    gridded(out_krig2)=T
    KrigRaster = raster(out_krig1)
    VarRaster = raster(out_krig2)
    plot(KrigRaster,main = "Interpolation Raster Plot",cex.main = 1.5)
    plot(VarRaster,main = "Variance Raster Plot", cex.main =  1.5)
    dev.off()
  }
  message("...done...almost...")
  return(out_params)
}