####App Manifold Learning
library(networkD3)

shinyUI(fluidPage(
  tags$head(
    tags$style(HTML("
      
      body {
        background-color: black;
        color:white
      }
      svg {
        color:white;
      }
      .well {
        background-color:black;
        color:white;
      }

    "))
  ),
  titlePanel("Subir archivo"),
  sidebarLayout(
    sidebarPanel(width = 3,
      fileInput('file1', 'Escoge archivo a subir, debe ser formato csv',
                accept = c(
                  '.csv'
                )
      ),
      tags$hr(),
      tags$h4("Escoge parametros"),
      sliderInput("slider1", label = "Intervalos", min = 1, 
                  max = 100, value = 10),
      sliderInput("slider2", label = "Overlaping", min = 0, 
                  max = .9, value = .2),
      sliderInput("slider3", label = "Vecinos cercanos", min = 1, 
                  max = 50, value = 5),
      
      actionButton("goButton", "Analizar"),
      p('Para ejecutar el análisis presionar el boton'
        ),
      selectInput("select","Colores","PC1")
    ),
    
    mainPanel(width = 9,
              forceNetworkOutput("force", height = "700px")
    )
  )
))

