if (!require(dplyr)) {
    install.packages("dplyr")
}
library(dplyr)
if (!require(sf)) {
    install.packages("sf")
}
library(sf)
if (!require(stringr)) {
    install.packages("stringr")
}
library(stringr)
if(!require(lubridate)){
    install.packages("lubridate")
}
library(lubridate)
if(!require(tidyr)){
    install.packages("tidyr")
}
library(tidyr)
if(!require(htmltools)){
    install.packages("htmltools")
}
library(htmltools)
if(!require(sp)){
    install.packages("sp")
}
library(sp)
if(!require(ggplot2)){
    install.packages("ggplot2")
}
library(ggplot2)
if(!require(data.table)){
  install.packages("data.table")
}
library(data.table)
#追加####
if(!require(curl)){
  install.packages("curl")
}
library(curl)
####
shinyServer(function(input, output, session) {
    load("files.RData")
    data7<-
      fread("https://raw.githubusercontent.com/tanamym/covid19_colopressmap_isehara/main/coviddata.csv",encoding="UTF-8")%>%
      #read.csv("https://raw.githubusercontent.com/tanamym/covid19_colopressmap_isehara/main/coviddata.csv",encoding="UTF-8")%>%  
      mutate(Fixed_Date=as.Date(Fixed_Date),
             Residential_City=str_replace(Residential_City,".+外.*","その他"))%>%
      mutate(Residential_City=ifelse(Hos!="川崎市",str_replace(Residential_City,"川崎市|東京都","その他"),Residential_City))#%>%
    #filter(Residential_City=="その他",Hos=="相模原")
    date<-
        data7%>%
        data.frame()%>%
        arrange(desc(Fixed_Date))%>%
        distinct(Fixed_Date)
    output$date<-
        renderUI({
            dateInput("x",
                      label = NULL,
                      #label = "日付を入力(選択)してください",
                      min = "2020-04-21",
                      max = date[1,1],
                      value = date[1,1])
        })
    output$update<-
        renderUI({
            h5(paste0("2020-04-21記者発表資料から",date[1,1],"記者発表資料掲載分まで集計しています。"))
        })


    yoko<-
        read.csv("https://square.umin.ac.jp/kenkono/csv/ward-new.csv",
                 encoding = "UTF-8",
                 header = F)
    
    yoko2<-
        yoko%>%
        filter(V1!="",V1!="区名")%>%
        tidyr::pivot_longer(-V1,
                            names_to = "V",
                            values_to="count")%>%
        rename("name"="V1")
    yoko3<-
        yoko%>%
        filter(V1=="")%>%
        tidyr::pivot_longer(-V1,
                            names_to="V",
                            values_to="year")%>%
        select(-V1)
    yoko4<-
        yoko%>%
        filter(V1=="区名")%>%
        tidyr::pivot_longer(-V1,
                            names_to="V",
                            values_to="date")%>%
        select(-V1)
    data<-
        left_join(yoko3,yoko4)%>%
        left_join(yoko2)%>%
        filter(!name%in%c("日本","横浜市","調査中","神奈川県"))%>%
      mutate(name=str_replace(name,"市外","その他"))%>%
        rename("N03_004"="name")%>%
        mutate(count=as.numeric(as.character(count)))%>%#文字列にしてから数字に直す
        #filter(date=="4/16~4/22")%>%
        mutate(N03_003="横浜市")%>%
        mutate(start=str_replace(date,"~.+",""),
               end=str_replace(date,".*~",""))%>%
        mutate(end=str_replace(end," .+",""))%>%
        mutate(year2=str_replace(year,"年",""))%>%
        mutate(start=str_replace(start,"/","-"),
               end=str_replace(end,"/","-"),
               start=paste0(year2,"-",start),
               end=paste0(year2,"-",end),
               start=lubridate::ymd(start),
               end=lubridate::ymd(end))


    v<-reactiveValues(tomo=0,next1=0,yest=0,back=0,ac=0,count=0 )
    observeEvent(input$tabset,{
      if(input$tabset=="tab2"&v$count==0){
        updateRadioButtons(inputId="y",
                           selected = 7)
        v$count=1
      }
    })
    observeEvent(v$yest<input$yesterday|v$tomo<input$tomorrow|v$back<input$back|v$next1<input$next1,ignoreInit = T,{
      
      x=input$x
      
      if(v$yest<input$yesterday){
        v$yest<-input$yesterday
        x=max(x-1,as.Date("2020-04-21"))
        # if(x<"2020-04-21"){x<-"2020-04-21"}
        updateDateInput(inputId = "x",
                        #min = "2020-04-21",
                        #max = date[1,1],
                        value = x)
      }
      
      if(v$tomo<input$tomorrow){
        v$tomo<-input$tomorrow
        x<-min(x+1,date[1,1])
        # if(x>date[1,1]){x<-date[1,1]}
        updateDateInput(inputId = "x",
                        #min = "2020-04-21",
                        #max = max(date[1,1],x),
                        value = x)
      }
      if(v$back<input$back){
        v$back<-input$back
        x=max(x-7,as.Date("2020-04-21"))
        # if(x<"2020-04-21"){x<-"2020-04-21"}
        updateDateInput(inputId = "x",
                        # min = "2020-04-21",
                        # max = date[1,1],
                        value = x)
      }
      if(v$next1<input$next1){
        v$next1<-input$next1
        x<-min(x+7,date[1,1])
        # if(x>date[1,1]){x<-date[1,1]}
        updateDateInput(inputId = "x",
                        # min = "2020-04-21",
                        # max = date[1,1],
                        value = x)
      }
    })

    action1<-
    #追加####
      #&!is.null(input$label)
      eventReactive(!is.null(input$x)&!is.null(input$y)&!is.null(input$label),ignoreInit = T, {
        ####
        
            x<-lubridate::ymd(input$x)
            y<-as.numeric(input$y)
            

            date1<-
                x-y+1
            City[nrow(City)+1,]<-"その他"
            data7.1<-
                data7%>%
                dplyr::filter(Fixed_Date>=date1,
                              Fixed_Date<=x)%>%
                # dplyr::filter(Fixed_Date>="2021-04-24",
                #               Fixed_Date<="2021-04-24")%>%
                dplyr::group_by(Residential_City)%>%
                summarise(count=n())%>%
                full_join(City)%>%
                mutate(count=ifelse(is.na(count),0,count))%>%
                mutate(N03_004=Residential_City)%>%
                ungroup()%>%
                #select(-X,-Y)%>%
                #dplyr::filter(X>0,Y>0)%>%
                dplyr::filter(is.numeric(count))%>%
                ungroup()
            data8<-
              data7.1%>%
              summarise(count=sum(count))

            data7.2<-
                sp::merge(shp,
                          data7.1,
                          by="N03_004", all=F,duplicateGeoms = TRUE)%>%
              mutate(count2=ifelse(count>y*50,y*50,count))
            xy3<-left_join(xy,data7.1, by = "N03_004")

              print(input$label)
              ggplot(data7.2)+
                geom_sf(data=data7.2%>%filter(N03_004!="横浜市"),
                        aes(fill=count2,color=""))+
                geom_sf(data = data7.2%>%filter(N03_004=="横浜市"),
                        aes(color=""))+
                scale_fill_gradient(low = "white",high = "red",
                                    breaks=seq(0,y*50,ifelse(y==1,10,100)),
                                    limits=c(0,y*50))+
                scale_color_manual(values ="gainsboro",
                                   guide=F)+
                #geom_text(data=xy,aes(x=X,y=Y,label=N03_004))+
                geom_text(data=xy3,aes(x=X,y=Y,
                                       label=paste0(N03_004_2," ",round(count,1),"人")))+
                geom_text(data=data7.1%>%filter(N03_004=="その他"),aes(x=139.400,y=35.172,
                                       label=paste0(N03_004," ",round(count,1),"人")))+
                geom_text(data=data8,
                          aes(x=139.650599530497,y=35.6725125899093,label=paste("合計",count,"人")),size=8)+
                coord_sf(datum = NA) +
                theme_void()+
                ggtitle(paste(date1,x,sep = "~"))+
                #theme(plot.background=element_rect(fill = "lightgray", colour = "white"))
                theme(legend.background = element_rect(fill = "gray",size=10,colour="gray"),
                      legend.title = element_blank(),
                )


                         
                

        })
    
    output$covid_map <- renderPlot({
      action1()
        

        })
   
    action2<-
        
      eventReactive(!is.null(input$x)&!is.null(input$label),ignoreInit = T, {
             
             x<-lubridate::ymd(input$x)

        # data1<-data%>%
        #     dplyr::filter(end<=lubridate::ymd(x),
        #                   start<=lubridate::ymd(x)-6)%>%
        #     group_by(N03_004)%>%
        #     mutate(rank=dense_rank(desc(end)))%>%
        #     filter(rank==1)%>%
        #     ungroup()

            #x<-"2021-05-27"
             data1<-data%>%
               mutate(flag=ifelse(x<=end,1,ifelse(end<x,2,0)))%>%
               filter(as.numeric(flag)>0)%>%
               arrange(flag)
              if(data1[1,10]==1){
                data1<-data1%>%filter(x<=end,start<=x)
              }
              if(data1[1,10]==2){
                data1<-data1%>%mutate(max=max(end))%>%filter(end==max)
              }
             data2<-
               data1%>%
               summarise(count=sum(count))
        yoko_shp<-
            sp::merge(shp2, data1,
                          #filter(year==input$year1,date%in%input$d2)
                      by=c("N03_004","N03_003"), all=F,duplicateGeoms = TRUE)

        xy4<-left_join(xy2,data1, by = "N03_004")

          ggplot(yoko_shp)+
          geom_sf(aes(fill=count,color=""))+
          scale_fill_gradient(low = "white",high = "red",
                              breaks=seq(0,350,100),
                              limits=c(0,350))+
          scale_color_manual(values ="gainsboro",
                             guide=F)+
          geom_text(data=xy4,aes(x=X,y=Y,
                                 label=paste0(N03_004," ",count,"人")))+
            geom_text(data=data1%>%filter(N03_004=="その他"),aes(x=139.51,y=35.31,
                                   label=paste0(N03_004," ",count,"人")))+
          geom_text(data=data2,
                    aes(x=139.662493759456,y=35.616158,label=paste("合計",count,"人")),size=8)+
          #geom_text(data=xy2,aes(x=X,y=Y,label=N03_004))+
          coord_sf(datum = NA) +
          theme_void()+
          ggtitle(paste0(unique(as.character(yoko_shp$start)),"~",unique(as.character(yoko_shp$end))))+
          theme(legend.background = element_rect(fill = "gray",size=10,colour="gray"),
                legend.title = element_blank())
   
          
        })
                

    output$yoko_map<-renderPlot({
       action2()
    })
    action3<-
        
      eventReactive(!is.null(input$x)|!is.null(input$y)&!is.null(input$label), {     
        x<-lubridate::ymd(input$x)
        y<-as.numeric(input$y)


        date1<-x-y+1
        #集計
        data7.1<-data7%>%
            filter(Fixed_Date>=date1,Fixed_Date<=x)%>%
          # dplyr::filter(Fixed_Date>="2021-05-22",
          #               Fixed_Date<="2021-05-22")%>%
            group_by(Residential_City,X,Y)%>%
            summarise(count=n())%>%
            ungroup()%>%
            full_join(City)%>%
            mutate(count=ifelse(is.na(count),0,count))%>%
            dplyr::filter(is.numeric(count))%>%
            select(-X,-Y)
        jinko2<-left_join(data7.1,jinko,by=c("Residential_City"="City"))
        jinko3<-jinko2%>%
            mutate(count_j=count/jinko*100000)%>%
            dplyr::filter(is.numeric(count_j))%>%
            filter(!is.na(count_j))%>%
            mutate(N03_004=Residential_City)
        data8<-
          data7.1%>%
          summarise(count=sum(count))%>%
          cbind(jinko%>%filter(City=="総数"))%>%
          mutate(count_j=round(count/jinko*100000,1))

        data7.2<-
            sp::merge(shp, jinko3,
                      by="N03_004", all=F,duplicateGeoms = TRUE)%>%
          mutate(count_j=ifelse(count_j>y*8,y*8,count_j))

        xy3<-left_join(xy,jinko3, by = "N03_004")
      
          ggplot(data7.2)+ 
            geom_sf(data=data7.2%>%filter(N03_004!="横浜市"),
                    aes(fill=count_j,color=""))+
            geom_sf(data = data7.2%>%filter(N03_004=="横浜市"),
                    aes(color=""))+
            scale_fill_gradient(low = "white",high = "red",
                                breaks=seq(0,y*8,ifelse(y==1,2,10)),
                                limits=c(0,y*8))+
            scale_color_manual(values ="gainsboro",
                             guide=F)+
            #geom_text(data=xy,aes(x=X,y=Y,label=N03_004))+
            geom_text(data=xy3,aes(x=X,y=Y,
                                   label=paste0(N03_004_2," ",round(count_j,1),"人")))+
            geom_text(data=data8,
                      aes(x=139.64059,y=35.67251,label=paste("10万人当たりの感染者数",count_j,"人")),size=8)+
            coord_sf(datum = NA) +
            theme_void()+
            ggtitle(paste(date1,x,sep = "~"))+
            theme(legend.background = element_rect(fill = "gray",size=10,colour="gray"),
                  legend.title = element_blank())
       
        
       
        })
    output$covid_map2 <- renderPlot({
        action3()
        
    })
    action4<-
        
      eventReactive(!is.null(input$x)&!is.null(input$label), {
            x<-input$x


            data1<-data%>%
              mutate(flag=ifelse(x<=end,1,ifelse(end<x,2,0)))%>%
              filter(as.numeric(flag)>0)%>%
              arrange(flag)
            if(data1[1,10]==1){
              data1<-data1%>%filter(x<=end,x>=start)
            }
            if(data1[1,10]==2){
              data1<-data1%>%mutate(max=max(end))%>%filter(end==max)
            }
        data2<-
            left_join(data1,
                      jinko4,by=c("N03_004"="City"))%>%
            mutate(count_j=round(count/jinko*100000,1))
        yoko_shp2<-
            sp::merge(shp2, data2,
                      by=c("N03_004","N03_003"), all=F,duplicateGeoms = TRUE)
        xy4<-left_join(xy2,data2, by = "N03_004")
        data3<-
          data1%>%
          summarise(count=sum(count))%>%
          cbind(jinko%>%
                  filter(City=="横浜市"))%>%
          mutate(count_j=round(count/jinko*100000,1))
       
          ggplot(yoko_shp2)+
            geom_sf(data=yoko_shp2%>%
                      filter(N03_003=="横浜市"),aes(fill=count_j,color=""))+
            scale_fill_gradient(low = "white",high = "red",
                                breaks=seq(0,56,10),
                                limits=c(0,56))+
            geom_text(data=xy4,aes(x=X,y=Y,label=paste0(N03_004," ",count_j,"人")))+
          geom_text(data=data3,
                    aes(x=139.562493759456,y=35.616158,label=paste("10万人当たりの感染者数",count_j,"人")),size=8)+
            scale_color_manual(values ="gainsboro",
                             guide=F)+
            coord_sf(datum = NA) +
            theme_void()+
            ggtitle(paste0(unique(as.character(yoko_shp2$start)),"~",unique(as.character(yoko_shp2$end))))+
            theme(legend.background = element_rect(fill = "gray",size=10,colour="gray"),
                  legend.title = element_blank())
     
  
        })
    output$yoko_map2<-renderPlot({
        action4()
        
    })

})
