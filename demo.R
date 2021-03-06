# A demo shiny app for d3HeatmapMod
# run with shiny::runApp('demo.R')

library(shiny)

source('d3HeatmapMod.R')

server <- function(input, output) {

  callModule(d3HeatmapMod, 'test', data = reactive({mtcars}), scale = reactive({'column'}))

}

ui <- fluidPage(

  sidebarLayout(

    sidebarPanel(
      width = 3,
      d3HeatmapControl('test')

    ),

    mainPanel(
      width = 9,
      d3HeatmapPlot('test')

    )

  )

)

shinyApp(ui, server)
