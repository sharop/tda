

# By default, the file size limit is 5MB. It can be changed by
# setting this option. Here we'll raise limit to 9MB.
options(shiny.maxRequestSize = 9*1024^2)

library(networkD3)

shinyServer(function(input, output) {
  # read.csv(inFile$datapath, header = input$header,
  #          sep = input$sep, quote = input$quote)
  
  grafica_clusters <- eventReactive(input$goButton, {
    
    ####Aquí vamos a ejecutar el proceso de python desde linea
    ####comandos para crear el json
    system(paste("python script_manifold.py", 
                 input$file1$datapath,
                 input$slider1,
                 input$slider2,
                 input$slider3))
    
    nodes <- jsonlite::fromJSON("datos_nodos.json")
    links <- jsonlite::fromJSON("datos_links.json")
    
    forceNetwork(Links = links, Nodes = nodes, Source = "source",
                 Target = "target", Value = "value", NodeID = "name", fontSize = 15,
                 Nodesize = "size", Group = "group", opacity = 1, zoom = TRUE,
                 linkDistance = JS("function(d){return d.value * 100}"))
  })

  
  output$force <- renderForceNetwork({
    grafica_clusters()
  })

})