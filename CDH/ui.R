library(shiny)
library(leaflet)

fluidPage(
  
  titlePanel("Data in the Customer Data Hub"),

  sidebarLayout(
    sidebarPanel(
       sliderInput(inputId = "num",
                   label = "Number of countries to display:",
                   min = 2,
                   max = 20,
                   value = 4),
       
       actionButton(inputId = "action", label = "Update")
    ),
    
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Number of Countries", plotOutput("barplot")),
                  tabPanel("as Map", plotOutput("mapplot")),
                  tabPanel("as Leaflet", leafletOutput("leaflet")))
    )
  )
)
