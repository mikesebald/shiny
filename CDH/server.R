library(shiny)
library(RODBC)
library(ggplot2)

odbc.database = "biuser"
odbc.user = "biuser"
odbc.password = "test77"


# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  output$countries <- renderPlot({
    bi_odbc <-
      odbcConnect("MongoBI", uid = odbc.user, pwd = odbc.password)
    
    postal_address <- sqlQuery(bi_odbc,
                               query = "select * from record_actual_validated_postal_address")
    odbcClose(bi_odbc)
    
    countries <-
      table(postal_address$validated.postal_address.country_code)
    
    countries <- as.data.frame(sort(countries, decreasing = TRUE)[1:input$bins])
    colnames(countries) <- c("Country", "Frequency")
    
    ggplot(countries, aes(x = Country, y = Frequency)) +
      geom_bar(stat = "identity",
               fill = "lightblue",
               colour = "red") +
      geom_text(aes(label = Frequency), color = "palevioletred3", vjust = 1.5)

  })
})
