library(tidyverse)
library(shiny)
library(ggplot2)
library(plotly)

ui <- fluidPage(
  sidebarPanel(
    selectInput('dataset',label='Dataset', choices = c('roads', 'buildings', 'rbw')),
    selectInput('clustering', label='Clustering', choices=c('kmeans', 'hdbscan', 'ward','e_ward')),
    numericInput('param', label='Clustering Param:', min=2, max=10, value = 2)
  ),
  mainPanel(
    
    plotlyOutput('tsne'),
    textInput('name', 'Tile name:', value = character(0)),
    verbatimTextOutput('out'),
    fillRow(
      imageOutput('original'),
      imageOutput('recons'), height = 100
    ),
    hr(),
    uiOutput('knn')
  )
)

server <- function(input, output, session) {
  
  all_knn <- list(
    roads = read_csv('../data/analysis/knn/knn_roads.csv'),
    buildings = read_csv('../data/analysis/knn/knn_buildings.csv'),
    rbw = read_csv('../data/analysis/knn/knn_rbw.csv')
  )
  
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
  
  tsne <- reactive({
    read_csv(paste0('../data/analysis/',input$dataset,'/tsne30.csv'))
  })
  
  knn <- reactive({
    if(is.null(input$dataset)){
      NULL
    } else {
      all_knn[[input$dataset]]
    }
  })
    
  data <- reactive({
    t <- tsne()
    cc <- clusters()
    
    t %>%
      inner_join(cities, by='name') %>%
      inner_join(cc, by='name')
  })
  
  orig_dir <- reactive({paste0('../data/tiles/france-ghs-15-',input$dataset,'-cat/')})
  recons_dir <- reactive({paste0('../data/recons/france_15_',input$dataset,'_128_full/')})
  
  output$tsne <- renderPlotly({
    d <- data()
    ggplot(d, aes(label=name)) +
      geom_point(aes(tsne_x, tsne_y, fill=as.character(cluster)))
  })
  
  clicked <- reactive({
    d <- data()
    s <- event_data('plotly_click')
    if(length(s) == 0){
      updateTextInput(session, 'name', value=character(0))
      NULL
    } else {
      l <- as.list(s)
      chosen <- d[d$tsne_x==l$x & d$tsne_y==l$y,]
      updateTextInput(session, 'name', value=chosen$name)
      chosen
    }
  })
  
  output$out <- renderPrint({
    clicked()
  })
  
  output$original <- renderImage({
    c <- clicked()
    od <- orig_dir()
    
    if(is.null(c)){
      c
    } else {
      list(src = paste0(od, '/', c$name, '.png'), width=128, height=128, alt='original')
    }
  }, deleteFile=FALSE, )
  
  output$recons <- renderImage({
    c <- clicked()
    rd <- recons_dir()
    
    if(is.null(c)){
      c
    } else {
      list(src = paste0(rd, '/', c$name, '.png'), width=128, height=128, alt='reconstruction')
    }
  }, deleteFile=FALSE)
  
  output$knn <- renderUI({
    c <- clicked()
    nn <- knn()
    rd <- recons_dir()
    
    if(is.null(c)){
      c
    } else {
      print('a')
      image_output_list <- 1:10 %>% lapply(function(i){
        print(paste0('knn',i))
        imageOutput(paste0('knn',i))
      })
      print(image_output_list)
      do.call(fillRow, image_output_list)
    }
    
  })
  
  observe({
    c <- clicked()
    nn <- knn()
    rd <- recons_dir()
    
    if(is.null(c)) return()
    print(c)
    
    neighbours <- nn %>% filter(name == c$name) %>% select(2:11)
    print(neighbours)
    for (i in 1:8){
      local({
        my_i <- i
        imagename <-  paste0('knn', my_i)
        print(imagename)
        neighbour <- as.character(neighbours[[i]])
        print(neighbour)
        output[[imagename]] <- 
          renderImage(list(
            src = paste0(rd, '/', neighbour, '.png'), width=128, height=128, alt='neighbour'
          ), deleteFile = F)
      })
    }
  })
}

shinyApp(ui, server)