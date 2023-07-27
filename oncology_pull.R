library(glue)
library(odbc)
library(tidyverse)
library(DBI)
library(pool)
con <- dbPool(drv = odbc::odbc(), dsn = "OAO Cloud DB", timeout = 30)
drop_query <- glue("DROP TABLE ONCOLOGY_ACCESS")
date_1 <- "2021-01-01"
date_2 <- Sys.Date() - 1
reg_exp <- "\\[(.*?)\\]"
update_query <- glue("CREATE TABLE ONCOLOGY_ACCESS_NEW AS \\
SELECT h.*, count(*) over () totalRows \\
FROM( \\
SELECT g.*, 
ROW_NUMBER() OVER (PARTITION BY g.MRN, g.APPT_DTTM, g.APPT_TYPE, g.PROVIDER, g.APPT_STATUS ORDER BY g.MRN, g.APPT_DTTM, g.APPT_TYPE, g.PROVIDER, g.APPT_STATUS) AS Counts \\
FROM( \\
        Select a.DEPT_SPECIALTY_NAME, a.PROV_ID AS EPIC_PROVIDER_ID, a.REFERRING_PROV_NAME_WID AS REF_PROVIDER, a.MRN, a.PAT_NAME AS Patient_Name, a.ZIP_CODE, \\
        a.BIRTH_DATE, a.FINCLASS AS Coverage, a.APPT_MADE_DTTM, a.APPT_DTTM, a.PRC_NAME AS APPT_TYPE, a.APPT_LENGTH AS APPT_DUR, a.DERIVED_STATUS_DESC AS APPT_STATUS, \\
        a.APPT_CANC_DTTM, a.CANCEL_REASON_NAME As CANCEL_REASON, a.SIGNIN_DTTM, a.PAGED_DTTM, a.CHECKIN_DTTM, a.ARVL_LIST_REMOVE_DTTM AS ARRIVAL_REMOVE_DTTM, a.ROOMED_DTTM, \\
        a.FIRST_ROOM_ASSIGN_DTTM AS ROOM_ASSIGNED_DTTM, a.PHYS_ENTER_DTTM AS PROVIDERIN_DTTM, a.VISIT_END_DTTM, \\
        a.CHECKOUT_DTTM, a.TIME_IN_ROOM_MINUTES, a.CYCLE_TIME_MINUTES, a.VIS_NEW_TO_DEP_YN AS NEW_PT, a.LOS_NAME AS CLASS_PT, a.APPT_ENTRY_USER_NAME_WID AS APPT_SOURCE, \\
        a.ACCESS_CENTER_SCHEDULED_YN AS ACCESS_CENTER, a.VISIT_METHOD, a.VISIT_PROV_STAFF_RESOURCE_C AS RESOURCES, \\
        TO_CHAR(EXTRACT(year from a.APPT_DTTM)) Appt_Year, \\
        TO_CHAR(a.APPT_DTTM, 'DY') AS APPT_DAY, \\
        TO_CHAR(a.APPT_DTTM, 'MON') AS Appt_Month, \\
        TO_CHAR(a.APPT_DTTM, 'yyyy-mm') AS Appt_Month_Year, \\
        trunc(a.APPT_DTTM) AS Appt_Date_Year, \\
        a.LOS_CODE, b.*, c.ASSOCIATIONLISTA, c.ASSOCIATIONLISTB, c.ASSOCIATIONLISTT, \\
        c.INPERSONVSTELE, d.DISEASE_GROUP, e.*, \\
        TRIM(TRAILING FROM REGEXP_REPLACE(a.PROV_NAME_WID, '{reg_exp}', '')) AS Provider \\
        FROM MV_DM_PATIENT_ACCESS a \\
                            INNER JOIN ONCOLOGY_DEPARTMENT_GROUPINGS b on a.DEPARTMENT_ID = b.DEPARTMENT_ID and \\
                            a.CONTACT_DATE BETWEEN TO_DATE('{date_1} 00:00:00', 'YYYY-MM-DD HH24:MI:SS') \\
                            AND TO_DATE('{date_2} 23:59:59', 'YYYY-MM-DD HH24:MI:SS') \\
                          INNER JOIN ONCOLOGY_PRC_GROUPINGS c on a.PRC_NAME = c.PRC_NAME \\
                          LEFT JOIN ONCOLOGY_DISEASE_GROUPINGS d on a.PROV_ID = d.EPIC_PROVIDER_ID \\
                          LEFT JOIN ONCOLOGY_DX_CODES e on a.PRIMARY_DX_CODE = e.PRIMARY_DX_CODE \\
                                      LEFT JOIN ONCOLOGY_LOS_EXCLUSIONS f on a.LOS_CODE = f.LOS_CODE \\
                                                                    WHERE f.LOS_CODE IS NULL \\
                                                                    
        ) g 
    ) h 
WHERE h.Counts = 1")
oncology_index <- glue("CREATE index oncology_filter_index on ONCOLOGY_ACCESS_NEW (SITE, DEPARTMENT_NAME, DX_GROUPER, APPT_DTTM, APPT_DAY)")
poolWithTransaction(con, function(conn) {
  # if(dbExistsTable(conn, "ONCOLOGY_ACCESS")) {
  #   dbExecute(conn,drop_query)
  # }
  dbExecute(conn,update_query)
  dbExecute(conn,oncology_index)
  
})