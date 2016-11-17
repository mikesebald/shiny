library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Countries in CDH"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
       sliderInput("bins",
                   "Number of countries to display:",
                   min = 2,
                   max = 20,
                   value = 4)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("countries")
    )
  )
))
