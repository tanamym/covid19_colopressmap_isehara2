library(dplyr)
library(data.table)
library(sf)
City<-
  data.frame(Residential_City=c("相模原市","横浜市","藤沢市","横須賀市","茅ヶ崎市","三浦市","綾瀬市",
                                "大和市","厚木市","鎌倉市","平塚市","小田原市","湯河原町","真鶴町",
                                "愛川町","座間市","伊勢原市","開成町","海老名市","寒川町","南足柄市",
                                "大井町","秦野市","箱根町","葉山町","逗子市","山北町","大磯町",
                                "二宮町","中井町","清川村","松田町","川崎市麻生区","川崎市宮前区",
                                "川崎市川崎区","川崎市高津区","川崎市幸区","川崎市中原区",
                                "川崎市多摩区"))

jinko<-read.csv("jinko.csv",fileEncoding = "UTF-8")
jinko<-data.frame(jinko)
jinko4<-read.csv("jinko2.csv",fileEncoding = "UTF-8")
jinko4<-data.frame(jinko4)

shp<-
  read_sf("N03-190101_14_GML/N03-19_14_190101_2.shp",options = "ENCODING=sJIS")

shp2 <-read_sf("N03-190101_14_GML/N03-19_14_190101.shp",options = "ENCODING=CP932") 

xy<-read.csv("cen_xy.csv",encoding = "UTF-8")%>%
  mutate(N03_004_2=str_replace(N03_004,"川崎市",""))
xy2<-read.csv("cen_xy2.csv",encoding = "UTF-8")


