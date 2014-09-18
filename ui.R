library(shiny)
shinyUI(
    navbarPage(
        "GTQ-US$ Exchange Rate",
        tabPanel(
            "How to Use",
            fluidPage(
                fluidRow(
                    column(4,
                           h4("What is this App?"),
                           p("This is an app that helps you analize the short-term and long term 
                             trend of the exchange rate between guatemalan quetzal and US dollar."),
                           p("The data comes from Guatemalan Central Bank's",
                             a(href="http://banguat.gob.gt/default.asp?lang=2", "website"), 
                             "and it is read using the site's webservices every time the app starts 
                             (that is, each time you open or refresh the web page), which means this 
                             app will allways display the most current information available from 
                             the central bank."),
                           p("The app itself is divided into three tabs. Each tab displays different information:"),
                           tags$ol(
                               tags$li("How to Use: This page"),
                               tags$li("Daily Exchange Rate"),
                               tags$li("Monthly Exchange Rate")
                               )
                             
                    ), ## First column ends (basic description)
                    column(4,
                           h4("Daily Exchange Rate"),
                           p("This tab displays a plot of the daily exchange rate from January 1st,
                             2000 until the last day available from banguat's website. Each line in
                             the plot represents a year, and you can choose which years to display
                             by checking the boxes to the left of the plot (initially, years 2011 - 
                             2014 are displayed)."),
                           p("It might take some time to display the plot the first time you visit 
                             this tab, since the data is being read and transformed in order to draw 
                             the plot. Once the data is loaded, changing the years is a lot faster"),
                           p("Below the plot, the exchange rate for the last 7 days is displayed.")
                    ), ## Second column ends (daily)
                    column(4, 
                           h4("Monthly Exchange Rate"),
                           p("In the last tab there is a monthly summary of exchange rates. In the 
                             left part of this tab, you can select the summarization method:"),
                           tags$ul(
                               tags$li("Average: The mean exchange rate for the month"),
                               tags$li("Maximum: The highest exchange rate for the month"),
                               tags$li("Minimum: The lowest exchange rate for the month"),
                               tags$li("Opening: The exchange rate for the first day of the month"),
                               tags$li("Closing: The exchange rate for the last day of the month")
                           ),
                           p("You can also select how many months forward to forecast the exchange rate.
                             This forecast is calculated using an ARIMA model and hence it is dependent 
                             only on the previous observations of the exchange rate."
                           ),
                           p("The plot in this tab shows the observed exchange rate (summarized by the
                             chosen variable) as a blue line and the forecasted values as a solid red 
                             line. Dotted red lines are used to show the 95% confidence interval for 
                             the forecast."),
                           p("Below this plot, you will find the forecasted values for the chosen 
                             variable and the desired forecast horizon.")
                    )## Third column ends (monthly)
                )
            )
        ), ## tabPanel("How to Use") Ends
        tabPanel(
            "Daily Exchange Rate", 
            fluidPage(
                titlePanel("Daily GTQ - US$ Exchange Rate from Jan 1, 2000"),
                sidebarLayout(
                    sidebarPanel(
                        h4("Select Years"),
                        p("Please choose the years for which you would like to see the exchange rate ploted"),
                        checkboxGroupInput(
                            "Years", 
                            label="",
                            choices = list(
                                "2000" = 2000,
                                "2001" = 2001,
                                "2002" = 2002,
                                "2003" = 2003,
                                "2004" = 2004,
                                "2005" = 2005,
                                "2006" = 2006,
                                "2007" = 2007,
                                "2008" = 2008,
                                "2009" = 2009,
                                "2010" = 2010,
                                "2011" = 2011,
                                "2012" = 2012,
                                "2013" = 2013,
                                "2014" = 2014),
                            selected = c(2011, 2012, 2013, 2014)
                        )
                    ),
                    mainPanel(
                        ##img(src="logo.png"),
                        plotOutput("XRatePlot"),
                        h4("Selected Years:"),
                        verbatimTextOutput("selected"),
                        h4("Exchange Rate for the Last 7 Days:"),
                        verbatimTextOutput("XRateLastN")
                        )
                )
            )
        ), ## tabPanel("Daily Exchange Rate") Ends
        tabPanel(
            "Monthly Exchange Rate",
            fluidPage(
                titlePanel("Monthly GTQ - US$ Exchange Rate"),
                sidebarLayout(
                    sidebarPanel(
                        h4("Select Function"),
                        p("Please choose summarization method for exchange rates"),
                        radioButtons(
                            "SelectedF", 
                            label = "",
                            choices = list(
                                "Average" = "1",
                                "Maximum" = "2",
                                "Minimum" = "3",
                                "Opening" = "4",
                                "Closing" = "5"
                            ),
                            selected = "1"
                        ),
                        sliderInput(
                            "m.pred",
                            "Months to Forecast:",
                            min = 3, max = 24, value = 6, step= 3)
                    ),
                    mainPanel(
                        ## img(src="logo.png"),
                        plotOutput("SummaryPlot"),
                        h4("Exchange Rate Forecast:"),
                        verbatimTextOutput("Forecasts")
                    )
                )
            )
        ) ## tabPanel("Monthly Exchange Rate") Ends
    ) ## navbarPage() Ends
) ## shinyUI() Ends