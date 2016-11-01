# shiny module of d3Heatmap
# This module is used in a shiny app for heatmap ploting
# Usage:
# 1. source this file in app.R or server.R
# 2. add d3HeatmapUI('MODULE_ID') in ui
# 3. add callModule(d3HeatmapMod, id = 'MODULE_ID', data, dendrogram, scale)
#    in server, where:
#    data: numeric matrix for plot
#    dendrogram: either NULL, 'row', 'column' or 'both'
#    scale: either NULL, 'row' or 'column'

d3HeatmapControl <- function(id) {
  ns <- NS(id)

  dendrogram_sel <- radioButtons(ns('dendrogram'), 'Dendrogram:',
                                 choices = c('none', 'row', 'column', 'both'))

  scale_sel <- radioButtons(ns('scale'), 'Scale:',
                            choices = c('none', 'row', 'column'))

  transpose_btn <- actionButton(ns('transpose'), 'Transpose',
                                icon = icon('retweet'))

  width_sld <- sliderInput(ns('width'), 'Width:',
                           min = 30, max = 900, value = 850, step = 10)

  height_sld <- sliderInput(ns('height'), 'Height:',
                           min = 30, max = 900, value = 850, step = 10)

  xfont_sel <- selectInput(ns('xfont'), 'X-axis font size:',
                           choices = c('auto',paste0(seq(10, 40, 2), 'px')),
                           selected = 'auto')

  yfont_sel <- selectInput(ns('yfont'), 'Y-axis font size:',
                           choices = c('auto',paste0(seq(10, 40, 2), 'px')),
                           selected = 'auto')

  download_btn <- downloadButton(ns('download'), 'Download heatmap')

  tagList(
    dendrogram_sel,
    scale_sel,
    width_sld,
    height_sld,
    xfont_sel,
    yfont_sel,
    transpose_btn,
    br(), br(),
    download_btn
  )
}

d3HeatmapPlot <- function(id) {
  ns <- NS(id)
  d3heatmap::d3heatmapOutput(ns('heatmap'), width = 1000, height = 1000)
}

d3HeatmapUI <- function(id) {

  fluidRow(
    column(
      width = 10,
      d3HeatmapPlot(id)
    ),
    column(
      width = 2,
      d3HeatmapControl(id)
    )
  )
}

d3HeatmapMod <- function(input, output, session, data,
                         dendrogram = reactive(NULL),
                         scale = reactive(NULL)) {

  d3Heatmap_plotdata <- reactive({
    `if`(input$transpose %% 2 == 0, data(), t(data()))
  })

  heatmap_obj <- reactive({
    d3heatmap::d3heatmap(d3Heatmap_plotdata(),
                         dendrogram = input$dendrogram, scale = input$scale,
                         # colors = rev(RColorBrewer::brewer.pal(9, 'RdYlBu')),
                         colors = 'Blues',
                         xaxis_height = 1000 - input$height,
                         yaxis_width = 1000 - input$width,
                         xaxis_font_size = `if`(input$xfont == 'auto',
                                                NULL, input$xfont),
                         yaxis_font_size = `if`(input$yfont == 'auto',
                                                NULL, input$yfont))
  })

  observeEvent(input$transpose, {
    if(input$dendrogram == 'row') {
      updateRadioButtons(session, 'dendrogram', selected = 'column')
    } else if(input$dendrogram == 'column') {
      updateRadioButtons(session, 'dendrogram', selected = 'row')
    }

    if(input$scale == 'row') {
      updateRadioButtons(session, 'scale', selected = 'column')
    } else if(input$scale == 'column') {
      updateRadioButtons(session, 'scale', selected = 'row')
    }

    updateSelectInput(session, 'xfont', selected = input$yfont)
    updateSelectInput(session, 'yfont', selected = input$xfont)
  })

  observe({
    n_col <- ncol(d3Heatmap_plotdata())
    n_row <- nrow(d3Heatmap_plotdata())

    if(n_row >= n_col) {
      height <- 600
      width <- n_col * height / n_row
    } else {
      width <- 600
      height <- n_row * width / n_col
    }

    if(input$dendrogram == 'row') {
      width <- width + 120
    } else if(input$dendrogram == 'column') {
      height <- height + 120
    } else if(input$dendrogram == 'both') {
      width <- width + 120
      height <- height + 120
    }

    updateSliderInput(session, 'width', value = width)
    updateSliderInput(session, 'height', value = height)
  })

  observeEvent(dendrogram(), {
    updateRadioButtons(session, 'dendrogram', selected = dendrogram())
  })

  observeEvent(scale(), {
    updateRadioButtons(session, 'scale', selected = scale())
  })


  output$heatmap <- d3heatmap::renderD3heatmap({
    heatmap_obj()
  })

  output$download <- downloadHandler(
    filename = 'heatmap.html',
    content = function(file) {
      htmlwidgets::saveWidget(heatmap_obj(), file)
    }
  )

}
