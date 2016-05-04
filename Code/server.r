

# By default, the file size limit is 5MB. It can be changed by
# setting this option. Here we'll raise limit to 9MB.
options(shiny.maxRequestSize = 9*1024^2)

library(networkD3)

shinyServer(function(input, output,session) {
  
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
    nombres_var <- names(nodes)[!names(nodes) %in% c("group","name","size")]
    
    list(nodes = nodes, links = links, nombres_var = nombres_var)
  })

  output$force <- renderForceNetwork({
    
    nodes <- grafica_clusters()$nodes
    links <- grafica_clusters()$links
    
    vector_para_colores <- nodes[[input$select]]
    min_obs <- min(vector_para_colores)
    max_obs <- max(vector_para_colores)
    mitad_rango <- ((max_obs -min_obs)/2) + min_obs
    nodes$rango_colores <- (vector_para_colores - mitad_rango)/((max_obs -min_obs)/2)
    
    forceNetwork(Links = links, Nodes = nodes, Source = "source",
                 Target = "target", Value = "value", NodeID = input$select, fontSize = 15,
                 Nodesize = "size", Group = "rango_colores", opacity = 1, zoom = TRUE,
                 colourScale = JS("d3.scale.linear().domain([-1,0,1]).range(['#005b96','#a7adba','#fe2e2e'])"),
                 linkDistance = JS("function(d){return d.value * 100}"))
    
  })
  
  observe({
    updateSelectInput(session, "select",
                      choices = grafica_clusters()$nombres_var
    )})

})