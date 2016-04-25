####Codigo para graficar los clusters en R, recordar que se tiene que crear el json antes.
####Librerías a instalar
######install.packages("networkD3")
######install.packages("jsonlite")

library(networkD3)
MisJson <- jsonlite::fromJSON("data.json")

forceNetwork(Links = MisJson$links, Nodes = MisJson$nodes, Source = "source",
             Target = "target", Value = "value", NodeID = "name", fontSize = 70,
             Nodesize = "size", Group = "group", opacity = 1, zoom = TRUE)