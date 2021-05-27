library(sf)
library(dplyr)

shp<-
  read_sf("N03-190101_14_GML/N03-19_14_190101_2.shp",options = "ENCODING=sJIS")
shp2<-
  read_sf("N03-190101_14_GML/N03-19_14_190101.shp",options = "ENCODING=CP932") 

xy<-
  shp%>%
  st_centroid()%>%
  st_coordinates()%>%
  data.frame()%>%
  cbind(shp%>%
          st_set_geometry(NULL))%>%
  arrange(X,-Y)%>%
  distinct(N03_004,.keep_all = T)

write.csv(xy,"cen_xy.csv",fileEncoding = "UTF-8",
          row.names = F)
xy2<-
  shp2%>%
  st_centroid()%>%
  st_coordinates()%>%
  data.frame()%>%
  cbind(shp2%>%
          st_set_geometry(NULL))%>%
  arrange(X,Y)%>%
  distinct(N03_004,.keep_all = T)%>%
  filter(str_detect(N03_003,"横浜市"))
write.csv(xy2,"cen_xy2.csv",fileEncoding = "UTF-8",
          row.names = F)

