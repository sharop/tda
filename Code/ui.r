####App Manifold Learning
library(networkD3)

shinyUI(fluidPage(
  titlePanel("Subir archivo"),
  sidebarLayout(
    sidebarPanel(
      fileInput('file1', 'Escoge archivo a subir, debe ser formato csv',
                accept = c(
                  '.csv'
                )
      ),
      tags$hr(),
      tags$h3("Escoge parametros"),
      sliderInput("slider1", label = h3("Intervalos"), min = 1, 
                  max = 100, value = 10),
      sliderInput("slider2", label = h3("Overlaping"), min = 0, 
                  max = .9, value = .2),
      sliderInput("slider3", label = h3("Vecinos cercanos"), min = 1, 
                  max = 50, value = 5),
      
      actionButton("goButton", "Analizar"),
      p('Para ejecutar el análisis presionar el boton'
        )
    ),
    
    mainPanel(
      forceNetworkOutput("force")
    )
  )
))

