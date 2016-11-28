library(rgeos)
library(maptools)
library(sp)
library(rgdal)
library(broom)
library(ggplot2)
library(RODBC)
library(microbenchmark)
library(data.table)
library(sqldf)
library(dplyr)

# data source: http://www.naturalearthdata.com/downloads/50m-cultural-vectors/
world <- readOGR(dsn = "../shiny_data/ne_50m_admin_0_countries.shp",
                 layer = "ne_50m_admin_0_countries")

# remove antarctica
world <- world[!world$iso_a3 %in% c("ATA"), ]

# change projection
world <- spTransform(world, CRS("+proj=wintri"))

# group coordinates by ISO2 country code
map <- tidy(world, region = "iso_a2")

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


odbc.database = "biuser"
odbc.user = "biuser"
odbc.password = "test77"
odbc.connection = "MongoBI"

message("Connecting to database")
bi_odbc <-
  odbcConnect(dsn = odbc.connection, uid = odbc.user, pwd = odbc.password)

odbc.tables <- sqlTables(bi_odbc)

message("Reading data")
microbenchmark({
  postal_address <- sqlQuery(bi_odbc,
                             query = "select * from record_actual_validated_postal_address")
}, times = 1)

query <- "select _id, date from revision where _id = '1'"
query <- "select _id, date from revision where date > '2016-11-22 12:00:00'"
query <- "select MIN(_id) from revision where date > '2016-11-22 12:00:00'"

from.date <- "2016-11-22 12:00:00"
to.date   <- "2016-11-22 13:00:00"

query <- paste0("select MIN(_id) from revision where date > '",
                from.date,
                "'")
min.rev <- sqlQuery(bi_odbc, query)
query <- paste0("select MAX(_id) from revision where date < '",
                to.date,
                "'")
max.rev <- sqlQuery(bi_odbc, query)

record_actual <- sqlQuery(bi_odbc, "select * from record_actual limit 200", as.is = TRUE)

query <- paste0("SELECT * FROM record_actual_validated_person_validation_message WHERE \"validated.status\" = 'invalid'")
cat(query)
validated_person <- sqlQuery(bi_odbc, 
                             query,
                             as.is = TRUE)


query <- paste0("SELECT * FROM record_actual_validated_person where \"validated.status\" = 'invalid'")
cat(query)
invalid_persons <- sqlQuery(bi_odbc, 
                            query,
                            as.is = TRUE)

query <- paste0("SELECT COUNT(*) FROM record_actual_validated_postal_address where \"validated.postal_address.status\" = 'invalid'")
cat(query)
num_inv_person_addresses <- sqlQuery(bi_odbc, 
                                     query,
                                     as.is = TRUE)

query <- paste0("SELECT * FROM record_actual_validated_postal_address WHERE \"validated.postal_address.status\" = 'invalid' ORDER BY \"_id.k\"")
cat(query)
inv_person_addresses <- sqlQuery(bi_odbc, 
                                 query,
                                 as.is = TRUE)

query <- paste0("SELECT * FROM record_actual_validated_postal_address_validation_message WHERE \"validated.postal_address.status\" = 'invalid' ORDER BY \"_id.k\"")
query <- paste0("SELECT * FROM record_actual_validated_postal_address_validation_message WHERE \"validated.postal_address.validation_message.type\" = 'uniserv_address' AND \"validated.postal_address.status\" = 'invalid'")
cat(query)
inv_person_addresses_msgs <- sqlQuery(bi_odbc, 
                                 query,
                                 as.is = TRUE)
View(table(inv_person_addresses_msgs$validated.postal_address.validation_message.code))


# Point in time querying starts here

from.date <- "2016-11-22 12:00:00"
to.date   <- "2017-11-22 13:00:00"

query <- paste0("select MIN(_id) from revision where date > '",
                from.date,
                "'")
revision_from <- sqlQuery(bi_odbc, query)
query <- paste0("select MAX(_id) from revision where date < '",
                to.date,
                "'")
revision_to <- sqlQuery(bi_odbc, query)

rm(record_history_validated_postal_address_validation_message)
rm(record_history_validated_postal_address)

bi_odbc <-
  odbcConnect(dsn = odbc.connection, uid = odbc.user, pwd = odbc.password)

# TODO: need to check, if setorder() is necessary/makes a difference
query <-
  paste0("SELECT * FROM record_history_validated_postal_address_validation_message")
record_history_validated_postal_address_validation_message <-
  as.data.table(sqlQuery(bi_odbc, query))
record_history_validated_postal_address_validation_message$`_id.k` <-
  as.character(record_history_validated_postal_address_validation_message$`_id.k`)
setorder(record_history_validated_postal_address_validation_message, `_id.k`, -`_id.r`)

query <-
  paste0("SELECT * FROM record_history_validated_postal_address")
record_history_validated_postal_address <-
  as.data.table(sqlQuery(bi_odbc, query))
record_history_validated_postal_address$`_id.k` <-
  as.character(record_history_validated_postal_address$`_id.k`)
setorder(record_history_validated_postal_address, `_id.k`, -`_id.r`)

# Now do the join here
#
# Option 1
revision_to <- 19
query <- paste0("
  SELECT *
  FROM record_history_validated_postal_address_validation_message o
  INNER JOIN (
    SELECT a.\"_id.k\", a.\"_id.r\"
    FROM record_history_validated_postal_address a
    INNER JOIN (
      SELECT \"_id.k\", MAX(\"_id.r\") sidr
      FROM record_history_validated_postal_address
      WHERE \"_id.r\" <=",
      revision_to,
      " GROUP BY \"_id.k\"
    ) s
    ON (s.\"_id.k\" = a.\"_id.k\" AND sidr = a.\"_id.r\" AND
        a.\"validated.postal_address.status\" = 'invalid')
  ) q
  ON (o.\"_id.k\" = q.\"_id.k\" AND o.\"_id.r\" = q.\"_id.r\")
  WHERE o.\"validated.postal_address.validation_message.is_error\" = 1 AND
        o.\"validated.postal_address.validation_message.type\" = 'uniserv_address'
")
postal_validation_messages <- sqldf(query)
cbind(postal_validation_messages$`_id.k`, postal_validation_messages$`_id.r`)

x1 <- table(as.character(postal_validation_messages$validated.postal_address.validation_message.code))

# Option 2 - MUCH! faster
revision_to <- 19
relevant_revisions <- subset(record_history_validated_postal_address,
                                        `_id.r` <= revision_to)
highest_revisions <- relevant_revisions[ , max(`_id.r`), by = `_id.k`]
colnames(highest_revisions)[2] <- "_id.r"

setkey(record_history_validated_postal_address, `_id.k`, `_id.r`)
setkey(highest_revisions, `_id.k`, `_id.r`)

postal_address_errors <- record_history_validated_postal_address[highest_revisions, nomatch = 0] %>%
  subset(validated.postal_address.status == "invalid")

nrow(postal_address_errors)

setkey(record_history_validated_postal_address_validation_message, `_id.k`, `_id.r`)
postal_address_messages <- record_history_validated_postal_address_validation_message[postal_address_errors, nomatch = 0] %>%
  subset(validated.postal_address.validation_message.is_error == 1 & validated.postal_address.validation_message.type == "uniserv_address")

nrow(postal_address_messages)

x2 <- table(as.character(postal_address_messages$validated.postal_address.validation_message.code))
identical(x1, x2)

odbcClose(bi_odbc)
