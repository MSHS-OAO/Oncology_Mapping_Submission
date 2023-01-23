server <- function(input, output, session) {
  observeEvent(input$submit_oncology,{
    oncology_file <- input$oncology_mapping
    if(is.null(oncology_file)){
      return(NULL)
    } else {
      #oncology_filepath <- "Oncology Analytics Tool - Mappings - Saved 1.10.2023.xlsx"
      oncology_filepath <- oncology_file$datapath
      
      disease_mapping <- disease_grouping_process(oncology_filepath)
      department_mapping <- department_grouping_process(oncology_filepath)
      prc_mapping <- prc_grouping_process(oncology_filepath)
      los_mapping <- los_grouping_process(oncology_filepath)
      dx_mapping <- dx_grouping_process(oncology_filepath)
      
      append_sql(disease_mapping, "ONCOLOGY_DISEASE_GROUPINGS")
      append_sql(department_mapping, "ONCOLOGY_DEPARTMENT_GROUPINGS")
      append_sql(prc_mapping, "ONCOLOGY_PRC_GROUPINGS")
      append_sql(los_mapping, "ONCOLOGY_LOS_EXCLUSIONS")
      append_sql(dx_mapping, "ONCOLOGY_DX_CODES")
      
      showModal(modalDialog(
        title = "Success",
        paste0("The mapping data has been updated"),
        easyClose = TRUE,
        footer = NULL
      ))
      flag <- 1
      
      if(flag == 1) {
        source("oncology_pull.R")
        showModal(modalDialog(
          title = "Success",
          paste0("The Oncology Analytics Tool has been updated"),
          easyClose = TRUE,
          footer = NULL
        ))
      }
    }
  
    }
  )
  
}