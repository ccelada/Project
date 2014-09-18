---
title: "Exchange Rate App"
author: "Carlos Celada"
date: "September 18, 2014"
output: html_document
---
What is this App?
================

This is a shiny app that helps you analize the short-term and long term trend of the exchange rate between guatemalan quetzal and US dollar. The shinyapp itself is hosted at the shinyapp.io website. You can reach the app following this [link]("https://talent.shinyapps.io/Project/")

The data comes from Guatemalan Central Bank's [website]("http://banguat.gob.gt/default.asp?lang=2") and it is read using the site's webservices every time the app starts that is, each time you open or refresh the web page, which means this app will allways display the most current information available from the central bank.

The app itself is divided into three tabs. Each tab displays different information:

* How to Use: Display the same info as this document
* Daily Exchange Rate
* Monthly Exchange Rate


Daily Exchange Rate
===================

This tab displays a plot of the daily exchange rate from January 1st, 2000 until the last day available from banguat's website. Each line in the plot represents a year, and you can choose which years to display by checking the boxes to the left of the plot (initially, years 2011 - 2014 are displayed).

It might take some time to display the plot the first time you visit this tab, since the data is being read and transformed in order to draw the plot. Once the data is loaded, changing the years is a lot faster.

Below the plot, the exchange rate for the last 7 days is displayed.


Monthly Exchange Rate
====================

In the last tab there is a monthly summary of exchange rates. In the left part of this tab, you can select the summarization method:

* Average: The mean exchange rate for the month
* Maximum: The highest exchange rate for the month
* Minimum: The lowest exchange rate for the month
* Opening: The exchange rate for the first day of the month
* Closing: The exchange rate for the last day of the month

You can also select how many months forward to forecast the exchange rate. This forecast is calculated using an ARIMA model and hence it is dependent only on the previous observations of the exchange rate.

The plot in this tab shows the observed exchange rate (summarized by the chosen variable) as a blue line and the forecasted values as a solid red line. Dotted red lines are used to show the 95% confidence interval for the forecast.

Below this plot, you will find the forecasted values for the chosen variable and the desired forecast horizon.
