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
shinyServer(function(input, output, session) {
    load("files.RData")
    data7<-
        fread("https://raw.githubusercontent.com/tanamym/covid19_colopressmap_isehara/main/coviddata.csv",encoding="UTF-8")%>%
        mutate(Fixed_Date=as.Date(Fixed_Date))%>%
        filter(!is.na(X))
    date<-
        data7%>%
        data.frame()%>%
        arrange(desc(Fixed_Date))%>%
        distinct(Fixed_Date)
    output$date<-
        renderUI({
            dateInput("x",
                      label = "日付を入力してください",
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
        filter(!name%in%c("日本","横浜市","市外","調査中","神奈川県"))%>%
        rename("N03_004"="name")%>%
        mutate(count=as.numeric(count))%>%
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

    day1<-
        reactive({
            data%>%
                filter(year==input$year1)%>%
                distinct(date)
        })
    
    output$date2<-
        renderUI({
            selectInput("d2","日付を選択してください。",
                        choices=day1()
            )
        })

    action1<-
        eventReactive(input$action, {
            x<-input$x
            y<-input$y
            if(is.null(x)){
                x<-date[1,1]
            }
            date1<-
                lubridate::ymd(x)-as.numeric(y)+1
            
            data7.1<-
                data7%>%
                dplyr::filter(Fixed_Date>=date1,
                              Fixed_Date<=lubridate::ymd(x))%>%
                # dplyr::filter(Fixed_Date>="2021-04-24",
                #               Fixed_Date<="2021-04-24")%>%
                dplyr::group_by(Residential_City,X,Y)%>%
                summarise(count=n())%>%
                full_join(City)%>%
                mutate(count=ifelse(is.na(count),0,count))%>%
                mutate(N03_004=Residential_City)%>%
                ungroup()%>%
                select(-X,-Y)%>%
                #dplyr::filter(X>0,Y>0)%>%
                dplyr::filter(is.numeric(count))%>%
                ungroup()

            data7.2<-
                sp::merge(shp,
                          data7.1,
                          by="N03_004", all=F,duplicateGeoms = TRUE)
            xy3<-left_join(xy,data7.1, by = "N03_004")

            ggplot(data7.2)+ 
                geom_sf(data=data7.2%>%filter(N03_004!="横浜市"),
                        aes(fill=count,color=""))+
                geom_sf(data = data7.2%>%filter(N03_004=="横浜市"),
                        aes(color=""))+
                scale_fill_gradient(low = "white",high = "red",
                                    breaks=seq(0,as.numeric(y)*50,ifelse(y==1,10,100)),
                                    limits=c(0,as.numeric(y)*50))+
                scale_color_manual(values ="gainsboro",
                                   guide=F)+
                #geom_text(data=xy,aes(x=X,y=Y,label=N03_004))+
                geom_text(data=xy3,aes(x=X,y=Y,
                                       label=paste0(N03_004_2," ",count,"人")))+
                coord_sf(datum = NA) +
                theme_void()+
                ggtitle(paste(date1,lubridate::ymd(x),sep = "~"))+
                #theme(plot.background=element_rect(fill = "lightgray", colour = "white"))
                theme(legend.background = element_rect(fill = "gray",size=10,colour="gray"),
                      legend.title = element_blank())


        })
    output$covid_map <- renderPlot({
        action1()
        
        })
    action2<-
        eventReactive(input$action,{
             x<-input$x
        if(is.null(x)){
            x<-date[1,1]
        }
        data1<-data%>%
            dplyr::filter(end<=lubridate::ymd(x),
                          start<=lubridate::ymd(x)-6)%>%
            group_by(N03_004)%>%
            mutate(rank=dense_rank(desc(end)))%>%
            filter(rank==1)%>%
            ungroup()
       
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
            geom_text(data=xy4,aes(x=X,y=Y,label=paste0(N03_004," ",count,"人")))+
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
        eventReactive(input$action,{
            x<-input$x
        y<-input$y
        if(is.null(x)){
            x<-date[1,1]
        }
        date1<-lubridate::ymd(x)-as.numeric(y)+1
        #集計
        data7.1<-data7%>%
            filter(Fixed_Date>=date1,Fixed_Date<=lubridate::ymd(x))%>%
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
        

        data7.2<-
            sp::merge(shp, jinko3,
                      by="N03_004", all=F,duplicateGeoms = TRUE)

        xy3<-left_join(xy,jinko3, by = "N03_004")
        ggplot(data7.2)+ 
            geom_sf(data=data7.2%>%filter(N03_004!="横浜市"),
                    aes(fill=count_j,color=""))+
            geom_sf(data = data7.2%>%filter(N03_004=="横浜市"),
                    aes(color=""))+
            scale_fill_gradient(low = "white",high = "red",
                                breaks=seq(0,as.numeric(y)*8,ifelse(y==1,2,10)),
                                limits=c(0,as.numeric(y)*8))+
            scale_color_manual(values ="gainsboro",
                             guide=F)+
            #geom_text(data=xy,aes(x=X,y=Y,label=N03_004))+
            geom_text(data=xy3,aes(x=X,y=Y,label=paste0(N03_004_2," ",round(count_j,2),"人")))+
            coord_sf(datum = NA) +
            theme_void()+
            ggtitle(paste(date1,lubridate::ymd(x),sep = "~"))+
            theme(legend.background = element_rect(fill = "gray",size=10,colour="gray"),
                  legend.title = element_blank())


        })
    output$covid_map2 <- renderPlot({
        action3()
        
    })
    action4<-
        eventReactive(input$action,{
            x<-input$x
        if(is.null(x)){
            x<-date[1,1]
        }
            data1<-data%>%
                # dplyr::filter(end<=lubridate::ymd(x),
                #               start<=lubridate::ymd(x)-6)%>%
              dplyr::filter(end<="2021-05-22",
                            start<="2021-05-26")%>%
                group_by(N03_004)%>%
                mutate(rank=dense_rank(desc(end)))%>%
                filter(rank==1)%>%
                ungroup()

        data2<-
            left_join(data1,
                      jinko4,by=c("N03_004"="City"))%>%
            mutate(count_j=round(count/jinko*100000,2))
        yoko_shp2<-
            sp::merge(shp2, data2,
                      by=c("N03_004","N03_003"), all=F,duplicateGeoms = TRUE)
        xy4<-left_join(xy2,data2, by = "N03_004")

        ggplot(yoko_shp2)+
            geom_sf(data=yoko_shp2%>%
                      filter(N03_003=="横浜市"),aes(fill=count_j,color=""))+
            scale_fill_gradient(low = "white",high = "red",
                                breaks=seq(0,56,10),
                                limits=c(0,56))+
            geom_text(data=xy4,aes(x=X,y=Y,label=paste0(N03_004," ",round(count_j,2),"人")))+
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