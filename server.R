library(shiny)
library(RCurl)
library(XML)
library(lubridate)
library(ggplot2)
library(scales)
library(data.table)
library(forecast)
library(tidyr)
library(googleVis)
library(plotly)

## SOAP request Header Fields
headerFields <- c('Content-Type' = "text/xml; charset=utf-8", 
                  SOAPAction = "http://www.banguat.gob.gt/variables/ws/TipoCambioFechaInicial")

## SOAP request Body
body <- '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
        <TipoCambioFechaInicial xmlns="http://www.banguat.gob.gt/variables/ws/">
            <fechainit>01/01/2000</fechainit>
        </TipoCambioFechaInicial>
    </soap:Body>
</soap:Envelope>'

## get data from central bank's website via webservice
reader <- basicTextGatherer()
curlPerform(url="http://www.banguat.gob.gt/variables/ws/TipoCambio.asmx",
            httpheader = headerFields,
            postfields=body,
            writefunction=reader$update)

## Parse returned XML
xmldata <- xmlParse(reader$value(), asText=TRUE)
rootNode <- xmlRoot(xmldata)

## Determine # of records from XML
records <- as.numeric(xmlSApply(rootNode[[1]][[1]][[1]],xmlValue)[2])

## Build dataframe from XML
xrate <- data.frame(
    date=rep("",records),
    sell=rep(NA,records),
    buy=rep(NA,records),
    xRate=rep(NA,records),
    stringsAsFactors=FALSE)

for(i in 1:records){
    xrate[i,1:3] <- xmlSApply(rootNode[[1]][[1]][[1]][[1]][[i]],xmlValue)[-1]
}
## Convert exchange rates to numeric
xrate[,2] <- as.numeric(xrate[,2])
xrate[,3] <- as.numeric(xrate[,3])

## Prior to Dec 2006 central bank reported two exchange rate values (sell & buy)
## Starting Dec 02, 2006 sell & buy values are equal and correspond to the 
## officialy reported "reference" exchange rate.
## For all dates, we consider the average between buy & sell values as the "reference" exchange rate
xrate[,4] <- (xrate[,2]+xrate[,3])/2

## Transform dates (imported as text) to actual dates (POSIX values)
xrate$date <- dmy(xrate$date)
xrate$year <- as.factor(year(xrate$date))

## This second date value will allow to plot different years in a single "time" axis
xrate$date2 <- ymd(paste0("2000",substr(as.character(xrate$date),5,10)))

## Create summaries for each variable in the second tab using data.table package
xrate$ym <- paste0(lubridate::year(xrate$date),lubridate::month(xrate$date,label=TRUE, abbr=TRUE))
x.rate <- data.table(xrate)
summary1 <- as.data.frame(x.rate[,mean(xRate),by=ym])
summary1$ym <- ymd(mapply(paste0, summary1$ym, rep("1",length(summary1$ym))))
names(summary1) <- c("ym","Actuals")
summary1$Forecast <- rep(NA, length(summary1$ym))
summary1$Max <- rep(NA, length(summary1$ym))
summary1$Min <- rep(NA, length(summary1$ym))

summary2 <- as.data.frame(x.rate[,max(xRate),by=ym])
summary2$ym <- ymd(mapply(paste0, summary2$ym, rep("1",length(summary1$ym))))
names(summary2) <- c("ym","Actuals")
summary2$Forecast <- rep(NA, length(summary2$ym))
summary2$Max <- rep(NA, length(summary2$ym))
summary2$Min <- rep(NA, length(summary2$ym))

summary3 <- as.data.frame(x.rate[,min(xRate),by=ym])
summary3$ym <- ymd(mapply(paste0, summary3$ym, rep("1",length(summary1$ym))))
names(summary3) <- c("ym","Actuals")
summary3$Forecast <- rep(NA, length(summary3$ym))
summary3$Max <- rep(NA, length(summary3$ym))
summary3$Min <- rep(NA, length(summary3$ym))

summary4 <- as.data.frame(x.rate[,.SD[1, xRate], by=ym])
summary4$ym <- ymd(mapply(paste0, summary4$ym, rep("1",length(summary1$ym))))
names(summary4) <- c("ym","Actuals")
summary4$Forecast <- rep(NA, length(summary4$ym))
summary4$Max <- rep(NA, length(summary4$ym))
summary4$Min <- rep(NA, length(summary4$ym))

summary5 <- as.data.frame(x.rate[,.SD[.N, xRate], by=ym])
summary5$ym <- ymd(mapply(paste0, summary5$ym, rep("1",length(summary1$ym))))
names(summary5) <- c("ym","Actuals")
summary5$Forecast <- rep(NA, length(summary5$ym))
summary5$Max <- rep(NA, length(summary5$ym))
summary5$Min <- rep(NA, length(summary5$ym))

## Create 5 different time series, one for each variable
for(i in 1:5){
    assign(paste0("ts", as.character(i)),ts(get(paste0("summary", as.character(i)))[,2],start=2000,freq=12))
}

## This dataframe is needed to label the summary plot (second tab)
summaryylabs <- data.frame(
    var = c("1", "2", "3", "4", "5"),
    titles=c("Average Exchange Rate in Month", 
             "Max Exchange Rate in Month", 
             "Min Exchange Rate in Month", 
             "Exchange Rate for First Day of Month", 
             "Exchange Rate for Last Day of Month")
    )

tidyXRate <- spread(xrate[,c("date2", "year", "xRate")], year, xRate)
original.columns <- ncol(tidyXRate)
original.names <- names(tidyXRate)
new.names <- paste0(names(tidyXRate)[2:original.columns],".html.tooltip")
for(i in 2:original.columns){
    tidyXRate[original.columns+i-1] <- paste0(format(tidyXRate$date2, "%b %d "), names(tidyXRate)[i], ": ", tidyXRate[,i])
}
names(tidyXRate) <- append(original.names, new.names)

## Actual shinyServer function
shinyServer(function(input, output) {
    output$selected <- renderPrint({as.numeric(input$Years)})
    ## This was the previous plot (using ggplot2), now uses plotly + ggplot2
    output$XRatePlot <- renderPlotly({
        ggplotly(ggplot(xrate[as.character(xrate$year) %in% input$Years,], aes(date2, xRate, group=year)) + 
            geom_line(aes(colour=year),size=.1) + scale_colour_hue(l=45) +
            labs(x="", y="Exchange Rate, GTQ/US$") +
            scale_x_datetime(labels = date_format("%b"), breaks = date_breaks("months")))
        })
    
    output$XRateLastN <- renderPrint({xrate[seq(records-6,records),c(1,4)]})
    
    ## Reactive expression that changes the gvis plot every time the selected years change
    LinePlot <- reactive ({
        Ys <- append(input$Years, paste0(input$Years, ".html.tooltip"))
        Ys <- Ys[order(Ys)]
        gplot <- gvisLineChart(data=tidyXRate, xvar="date2", yvar=Ys,
                               options=list(selectionMode="multiple", height = 600,
                                            chartArea="{left:50,top:5,width:'95%',height:'90%'}",
                                            legend = "{position:'in'}",
                                            hAxis="{format: 'MMM', gridlines: {count: 13}}", 
                                            vAxis="{title: 'Exchange Rate (US$ / GTQ)', gridlines: {count:10}}"))
        return(gplot)
        })
    ## Plot using google Vis
    output$gvisPlot <- renderGvis({
        LinePlot()
    })
    
    ## This reactive expression calculates the forecast for the selected variable. Forecasting is
    ## done each time the variable we wish to plot / forecast changes
    fit.x.rate <- reactive({
        auto.arima(get(paste0("ts",as.character(input$SelectedF))))
    })
    
    ## prediction changes every time the desired variable or the number of months to predict changes
    prediction <- reactive({
        forecast.Arima(fit.x.rate(),h=input$m.pred,level=95)
    })
    
    ## actual values must change every time the desired variable changes
    actuals <- reactive ({
        window(get(paste0("ts", as.character(input$SelectedF))),2014)
    })
    
    ## determine dates to be plotted (prediction horizon)
    predDates <- reactive({
        ## variable times needed as some results from time() function are inexact
        ## so trunc(time()) returns a year diffrent from what is expected
        times <- as.numeric(as.character(time(prediction()$mean)))
        ymd(mapply(paste, trunc(times),
                   round((times - trunc(times))*12 +1), 
                   rep(1,length(times)), sep="." ))
    })
    
    ## create data frame with predictions
    predSummary <- reactive({
        data.frame("ym"=predDates(), 
                   "Actuals"=rep(NA,length(prediction()$mean)), 
                   "Forecast"=prediction()$mean,
                   "Max"=as.numeric(prediction()$upper),
                   "Min"=as.numeric(prediction()$lower))
    })
    
    ## create complete data frame with actuals and predictions
    Summary <- reactive ({
        rbind(get(paste0("summary",as.character(input$SelectedF))),predSummary())
    })
    
    ## Original Summary Plot (using standard R plot)
    output$SummaryPlot <- renderPlot({
        TimeSeries <- get(paste0("ts", as.character(input$SelectedF)))
        plot(TimeSeries, col="blue", xlim=c(2000,2018), ylim=c(7.2,8.4), 
             ylab=summaryylabs[summaryylabs[,1]==input$SelectedF,2])
        lines(prediction()$mean, col="red")
        lines(ts(prediction()$lower, start=c(year(xrate[records,1]),month(xrate[records,1])+1), freq=12), 
              col="red", lty=3)
        lines(ts(prediction()$upper, start=c(year(xrate[records,1]),month(xrate[records,1])+1), freq=12), 
              col="red", lty=3)
        legend(x="topright",c("observed","forecast", "95% conf. interval"), col=c("blue", "red", "red"), lty=c(1,1,3))
    })
    
    ## Create GoogleVis Summary plot (must be reactive)
    SummaryLinePlot <- reactive({
        gvisLineChart(data=Summary(), xvar = "ym", yvar = c("Actuals","Forecast", "Max","Min"),
                      options=list(selectionMode="multiple", height = 400,
                                   chartArea="{left:50,top:5,width:'95%',height:'90%'}",
                                   legend = "{position:'in'}",
                                   hAxis="{format: 'y', gridlines:{count:5}}", 
                                   vAxis="{title: 'Exchange Rate (US$ / GTQ)', gridlines: {count:5}}"))
    })
    
    output$SummaryPlotGvis <- renderGvis({
        SummaryLinePlot()
    })
    
    output$Forecasts <- renderPrint({
        round(prediction()$mean,digits=3)
    })
    output$Actuals <- renderPrint({
        round(actuals(),digits=3)
    })
})