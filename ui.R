library(shiny)

# Define UI for app that draws a histogram ----
ui <- fluidPage(
  
  # App title ----
  titlePanel("Oncology Mapping Data Submission"),
  
  # Sidebar layout with input and output definitions ----
  #sidebarLayout(
    
    # Sidebar panel for inputs ----
    #sidebarPanel(

      # # Input: Slider for the number of bins ----
      # sliderInput(inputId = "bins",
      #             label = "Number of bins:",
      #             min = 1,
      #             max = 50,
      #             value = 30)

    #),

    #Main panel for displaying outputs ----
    mainPanel(
      
      fileInput("oncology_mapping", label = "Please upload Oncology mapping file"),
      actionButton("submit_oncology", label = "Submit")
      
    ),
  tags$style(HTML("
        #submit_oncology {
          background-color: #d80b8c;
          color: #FFFFFF;
          border-color: #d80b8c;
        }"))
  #)
)