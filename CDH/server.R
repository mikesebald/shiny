library(shiny)
library(RODBC)
library(rgeos)
library(maptools)
library(sp)
library(rgdal)
library(broom)
library(ggplot2)

odbc.database = "biuser"
odbc.user = "biuser"
odbc.password = "test77"

world <- readOGR(dsn = "../../shiny_data/ne_50m_admin_0_countries.shp",
                 layer = "ne_50m_admin_0_countries")

# remove antarctica
world <- world[!world$iso_a3 %in% c("ATA"), ]

# change projection
world <- spTransform(world, CRS("+proj=wintri"))

# group coordinates by ISO2 country code
map <- tidy(world, region = "iso_a2")

message("within server.R function")

function(input, output) {
  output$barplot <- renderPlot({
    
    input$action
    
    message("within barplot function")
    
    bi_odbc <-
      odbcConnect("MongoBI", uid = odbc.user, pwd = odbc.password)
    
    postal_address <- sqlQuery(bi_odbc,
                               query = "select * from record_actual_validated_postal_address")
    odbcClose(bi_odbc)
    
    countries <-
      table(postal_address$validated.postal_address.country_code)
    
    countries <- as.data.frame(sort(countries, decreasing = TRUE)[1:input$num])
    colnames(countries) <- c("Country", "Frequency")
    
    ggplot(countries, aes(x = Country, y = Frequency)) +
      geom_bar(stat = "identity",
               fill = "lightblue",
               colour = "red") +
      geom_text(aes(label = Frequency), color = "palevioletred3", vjust = 1.5)
  })
  
  output$mapplot <- renderPlot({
    input$action
    
    message("within mapplot function")
    
    bi_odbc <-
      odbcConnect("MongoBI", uid = odbc.user, pwd = odbc.password)
    
    postal_address <- sqlQuery(bi_odbc,
                               query = "select * from record_actual_validated_postal_address")
    odbcClose(bi_odbc)
    
    countries <-
      table(postal_address$validated.postal_address.country_code)
    
    countries <- as.data.frame(sort(countries, decreasing = TRUE)[1:input$num])
    colnames(countries) <- c("Country", "Frequency")

    gg <- ggplot()
    # first we add the map of the world to the plot
    gg <- gg + geom_map(data = map, map = map,
                        aes(x = long, y = lat, map_id = id, group = group),
                        fill = "white", color = "darkgrey")
    # then we add the actual data
    gg <- gg + geom_map(data = countries, map = map, color = "white", size = 0.15,
                        aes(fill = log(Frequency), group = Country, map_id = Country))
    # the rest is basically making the plot look nicer
    gg <- gg + scale_fill_gradient(low = "#f7fcb9", high = "#31a354", 
                                   name="Frequency (log) of addresses by country")
    gg <- gg + theme(axis.title.x = element_blank(),
                     axis.text.x = element_blank(),
                     axis.ticks.x = element_blank())
    gg <- gg + theme(axis.title.y = element_blank(),
                     axis.text.y = element_blank(),
                     axis.ticks.y = element_blank())
    gg <- gg + theme(legend.position = "bottom")
    gg <- gg + coord_equal(ratio = 1)
    gg    
    
  })
}

