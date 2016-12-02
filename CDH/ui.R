library(shiny)
library(leaflet)

fluidPage(
  
  fluidRow(
    column(8,
           titlePanel("Uniserv Customer Data Hub Insights")
    ),
    column(4,
           img(src = "uniserv.png", height = 86, width = 392),
           tags$head(tags$style(".rightAlign{float:right;}"))
    )
  ),
  fluidRow(
    column(2,
           wellPanel(
             actionButton(inputId = "action", label = "Update")
           )

           ),
    column(10,
           tabsetPanel(type = "tabs",
                       tabPanel("Number of Countries",
                                plotOutput("countries_plot"),
                                sliderInput(inputId = "num",
                                            label = "Number of countries to display:",
                                            min = 2,
                                            max = 20,
                                            value = 4)
                                ),
                       tabPanel("as Map", 
                                plotOutput("map_plot",
                                           height = 600,
                                           width = "100%")
                                ),
                       tabPanel("in Leaflet", 
                                leafletOutput("leaflet",
                                              height = 600)
                                ),
                       tabPanel("Validation Errors", 
                                plotlyOutput("address_errors",
                                           height = 500),
                                sliderInput(inputId = "revision_1",
                                            label = "Revision 1:",
                                            min = 1,
                                            max = 25,
                                            value = 5),                                
                                sliderInput(inputId = "revision_2",
                                            label = "Revision 2:",
                                            min = 1,
                                            max = 25,
                                            value = 10)                                
                       )
           )
    )
  )
)
