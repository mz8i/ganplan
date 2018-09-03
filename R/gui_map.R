library(sf)
library(shiny)
library(ggplot2)
library(plotly)
library(leaflet)

orig_dir <- '../data/tiles/france-ghs-15-roads-cat/'
recons_dir <- '../data/recons/france_15_roads_128/'

ui <- fluidPage(
  tags$style(type = "text/css", "#map {height: calc(70vh) !important;}"),
  sidebarPanel(
    selectInput('dataset',label='Dataset', choices = c('roads', 'buildings', 'rbw')),
    selectInput('clustering', label='Clustering', choices=c('kmeans', 'hdbscan', 'ward')),
    numericInput('param', label='Clustering Param:', min=2, max=10, value = 2)
  ),
  mainPanel(
    leafletOutput('map'),
    verbatimTextOutput('out'),
    numericInput('clusters', 'Clusters:', 2, min=2, max=20)
  )
)

server <- function(input, output, session) {
  
  
  tile_shapes <- st_read('../data/analysis/tiles.geojson')
  
  cities <- read_csv('../data/analysis/matched-ghs-fr-core.csv') %>%
    select(name, au)
  
  clusters <- reactive({
    path <- paste0('../data/analysis/',input$dataset,'/',input$clustering,input$param,'.csv')
    if(!file.exists(path)){
      NULL
    } else {
      read_csv(path)
    }
  })
  
  orig_dir <- reactive({paste0('../data/tiles/france-ghs-15-',input$dataset,'-cat/')})
  recons_dir <- reactive({paste0('../data/recons/france_15_',input$dataset,'_128_full/')})
  
  spatial_data <- reactive({
    cc <- clusters()
    if(is.null(cc)){
      NULL
    } else {
      print('joining tiles')
      tile_shapes %>%
        inner_join(cc, by='name') 
    }
  })
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles()
  })
  
  details <- function(name, cluster){
    paste(name, '-', cluster)  
  }
  observe({
    sd <- spatial_data()
    
    if(is.null(sd)) return()
    
    palette <- colorFactor(topo.colors(10), sd$kmeans)
    leafletProxy('map') %>%
      clearShapes() %>%
      addPolygons(data = sd, fillOpacity = 0.5, fillColor = ~palette(cluster),
                              color='black', weight=1,popup = ~details(name, cluster))
  })
  
}

shinyApp(ui, server)
