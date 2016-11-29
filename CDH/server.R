library(shiny)
library(RODBC)
library(rgeos)
library(maptools)
library(sp)
library(rgdal)
library(broom)
library(ggplot2)
library(leaflet)
library(htmltools)
library(data.table)

if (is.null(postal_address)) {
  odbc.database = "biuser"
  odbc.user = "biuser"
  odbc.password = "test77"
  odbc.connection = "MongoBI"
  
  message("Connecting to database")
  bi_odbc <-
    odbcConnect(dsn = odbc.connection, uid = odbc.user, pwd = odbc.password)
  
  message("Reading data")
  postal_address <- sqlQuery(bi_odbc,
                             query = "select * from record_actual_validated_postal_address")

  message("done. Disconnecting.")
  odbcClose(bi_odbc)
  
  world <-
    readOGR(dsn = "../../shiny_data/ne_50m_admin_0_countries.shp",
            layer = "ne_50m_admin_0_countries")
  
  # world <-
  #   readOGR(dsn = "../shiny_data/ne_50m_admin_0_countries.shp",
  #           layer = "ne_50m_admin_0_countries")
  
  # remove antarctica
  world <- world[!world$iso_a3 %in% c("ATA"),]
  
  # change projection
  world <- spTransform(world, CRS("+proj=wintri"))
  
  # group coordinates by ISO2 country code
  map <- tidy(world, region = "iso_a2")
}

message("within server.R function")

function(input, output) {
  output$countries_plot <- renderPlot({
    
    input$action
    
    message("within countries_plot function")

    countries <-
      table(postal_address$validated.postal_address.country_code)
    
    countries <- as.data.frame(sort(countries, decreasing = TRUE)[1:input$num])
    colnames(countries) <- c("Country", "Frequency")
    
    ggplot(countries, aes(x = Country, y = Frequency)) +
      geom_bar(stat = "identity",
               fill = "lightblue",
               colour = "red") +
      geom_text(aes(label = Frequency), color = "black", vjust = 1.5)
  })
  
  output$map_plot <- renderPlot({
    input$action
    
    message("within map_plot function")

    countries <-
      table(postal_address$validated.postal_address.country_code)
    
    countries <- as.data.frame(sort(countries, decreasing = TRUE))
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
    
  }, height = 600, width = 1000)
  
  output$leaflet <- renderLeaflet({
    message("within leafletplot function")

    input$action

    subs <- subset(postal_address, !is.na(postal_address$validated.postal_address.x_coord))
    subs <- subs[, c("_id.k", 
                     "_id.s", 
                     "validated.postal_address.x_coord", 
                     "validated.postal_address.y_coord", 
                     "validated.postal_address.str", 
                     "validated.postal_address.hno", 
                     "validated.postal_address.city")]
    colnames(subs) <- c("key", "source", "x", "y", "str", "hno", "city")

    coord <- subs$x
    subs$x <- as.numeric(paste0(substr((coord), 1, nchar(coord) - 5), 
                     ".", 
                     substr(coord, nchar(coord) - 4, nchar(coord))))
    coord <- subs$y
    subs$y <- as.numeric(paste0(substr((coord), 1, nchar(coord) - 5), 
                     ".", 
                     substr(coord, nchar(coord) - 4, nchar(coord))))

    m <- leaflet() %>%
      addTiles() %>%
      addMarkers(lng = subs$x,
                 lat = subs$y,
                 popup = htmlEscape(paste0(subs$str, " ", 
                                           subs$hno, ", ", 
                                           subs$city)),
                 clusterOptions = markerClusterOptions())
    m
  })
  
  output$address_errors <- renderPlot({
    
    input$action
    
    message("within address_errors function")
    
    revision_1 <- input$revision_1
    revision_2 <- input$revision_2
    
    relevant_revisions <- subset(record_history_validated_postal_address,
                                 `_id.r` <= revision_1)
    highest_revisions <- relevant_revisions[ , max(`_id.r`), by = `_id.k`]
    colnames(highest_revisions)[2] <- "_id.r"
    
    setkey(record_history_validated_postal_address, `_id.k`, `_id.r`)
    setkey(highest_revisions, `_id.k`, `_id.r`)
    
    postal_address_errors <- record_history_validated_postal_address[highest_revisions, nomatch = 0] %>%
      subset(validated.postal_address.status == "invalid")

    setkey(record_history_validated_postal_address_validation_message, `_id.k`, `_id.r`)
    postal_address_messages <- record_history_validated_postal_address_validation_message[postal_address_errors, nomatch = 0] %>%
      subset(validated.postal_address.validation_message.is_error == 1 & validated.postal_address.validation_message.type == "uniserv_address")
    
    messages_1 <- as.data.frame(table(as.character(postal_address_messages$validated.postal_address.validation_message.code)))
    messages_1 <- cbind(messages_1, revision_1)
    colnames(messages_1) <- c("Validation Message", "Frequency", "Revision")
    
    relevant_revisions <- subset(record_history_validated_postal_address,
                                 `_id.r` <= revision_2)
    highest_revisions <- relevant_revisions[ , max(`_id.r`), by = `_id.k`]
    colnames(highest_revisions)[2] <- "_id.r"
    
    setkey(record_history_validated_postal_address, `_id.k`, `_id.r`)
    setkey(highest_revisions, `_id.k`, `_id.r`)
    
    postal_address_errors <- record_history_validated_postal_address[highest_revisions, nomatch = 0] %>%
      subset(validated.postal_address.status == "invalid")
    
    setkey(record_history_validated_postal_address_validation_message, `_id.k`, `_id.r`)
    postal_address_messages <- record_history_validated_postal_address_validation_message[postal_address_errors, nomatch = 0] %>%
      subset(validated.postal_address.validation_message.is_error == 1 & validated.postal_address.validation_message.type == "uniserv_address")
    
    messages_2 <- as.data.frame(table(as.character(postal_address_messages$validated.postal_address.validation_message.code)))
    messages_2 <- cbind(messages_2, revision_2)
    colnames(messages_2) <- c("Validation Message", "Frequency", "Revision")

    messages <- rbind(messages_1, messages_2)
    messages$Revision <- as.factor(messages$Revision)
        
    ggplot(messages, aes(x = `Validation Message`, y = Frequency)) +
      geom_bar(aes(fill = messages$Revision), position = "dodge", stat = "identity")

  })  
}
