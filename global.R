library(odbc)
library(DBI)
library(readxl)
library(stringr)
library(dplyr)
library(glue)

conn <- dbConnect(odbc(), "OAO Cloud DB")

mapping_file_test <- "Oncology Analytics Tool - Mappings - Saved 1.10.2023.xlsx"

disease_grouping_process <- function(filepath) {
  
  #### Provider ID Mappings ------
  #import the disease grouping file
  disease_grouping <-
    read_excel(filepath,
               sheet = "Provider ID Mappings",
               range = cell_cols("A:D"))
  
  disease_grouping <- disease_grouping %>% 
    mutate(across(where(is.character), str_trim))
  
  #change column names for the disease grouping file
  colnames(disease_grouping) <- c("PROVIDER_NAME",
                                  "EPIC_PROVIDER_ID",
                                  "DISEASE_GROUP",
                                  "DISEASE_GROUP_B")
  
  return(disease_grouping)
  
}

department_grouping_process <- function(filepath) {
  #### Department Mappings ------
  department_mapping <-
    read_excel(filepath,
               sheet = "Site Mappings",
               range = cell_cols("A:D"))
  
  department_mapping <- department_mapping %>% 
    mutate(across(where(is.character), str_trim))
  #change column names for the department mapping
  colnames(department_mapping) <- c("DEPARTMENT_NAME",
                                    "DEPARTMENT_ID",
                                    "SITE",
                                    "DISPLAY_FILTER")
  
  return(department_mapping)
}

prc_grouping_process <- function(filepath) {
  #### PRC Mappings ------
  #import the department PRC mapping file
  PRC_mapping <-
    read_excel(filepath,
               sheet = "Visit Type Grouper",
               range = cell_cols("A:E"))
  ##remove the space at the end and at the beginning when applicable
  PRC_mapping$`PRC Name` <- str_trim(PRC_mapping$`PRC Name`)
  PRC_mapping$`PRC Name` <- toupper(PRC_mapping$`PRC Name`)
  
  #####change all to first word capitalized
  PRC_mapping$`Association List : A`[PRC_mapping$`Association List : A` == "Lab"] <- "Labs"
  PRC_mapping$`Association List : A` <- str_to_title(PRC_mapping$`Association List : A`)
  
  PRC_mapping$`Association List: B` <- str_to_title(PRC_mapping$`Association List: B`)
  
  PRC_mapping$`Association List: T` <- str_to_title(PRC_mapping$`Association List: T`)
  
  #change column names for the PRC mapping
  colnames(PRC_mapping) <- c("PRC_NAME",
                             "ASSOCIATIONLISTA",
                             "ASSOCIATIONLISTB",
                             "ASSOCIATIONLISTT",
                             "INPERSONVSTELE") 
  return(PRC_mapping)
}

los_grouping_process <- function(filepath) {
  #### LOS Exclusions ------
  #Import LOS Exclusions
  los_exclusions <- read_excel(filepath,
                               sheet = "LOS Exclusions",
                               range = cell_cols("A:C"))
  los_exclusions <- los_exclusions %>% rename(INCLUDE_EXCLUDE = `Include/ Exclude`)
  
  return(los_exclusions)
}

dx_grouping_process <- function(filepath) {
  #### #Dx Codes ------
  #Dx Codes
  dx_codes <- read_excel(filepath,
                         sheet = "Primary Dx Cancer Grouper",
                         range = cell_cols("A:C"))
  
  dx_codes <- dx_codes %>%
    rename(PRIMARY_DX_CODE = `Primary Diag Code`,
           DX_GROUPER = `Primary Dx - Cancer Grouper`,
           DX_DETAIL = `Primary Dx - Cancer Detail`,)
  
  return(dx_codes)
}

append_sql <- function(df, table_name) {
  truncate_query <- glue("TRUNCATE TABLE {table_name}")
  dbExecute(conn, truncate_query)
  dbAppendTable(conn, table_name, df)
}

