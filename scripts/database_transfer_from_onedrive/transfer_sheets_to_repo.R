#### User Defined Variables ####
if(Sys.info()['user'] == 'jdsel'){
  onedrive_path = "~/../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project/Database"
} else {
  onedrive_path = "../../../../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project (1)/Database/"
}


###### Vector of source Excel files ######
excel_files <- 
  c(
    "Extractions_sheet.xlsx",
    "Library_Contents_sheet.xlsx",
    "Lot_sheet.xlsx",
    "Individual_sheet.xlsx",
    "Library_Info_sheet.xlsx",
    "Sequence_info_sheet.xlsx",
    "Shipment_sheet.xlsx",
    "Species_sheet.xlsx"
  )

###### Corresponding destination directories (one level up from the working dir) ######
dest_dirs <- 
  c(
    "../../db_files/dna_extractions_sheets",
    "../../other_sheets",
    "../../db_files/lots_sheets",
    "../../db_files/individuals_sheets",
    "../../other_sheets",
    "../../db_files/sequence_info_sheets",
    "../../db_files/shipments_sheets",
    "../../db_files/species_sheets"
  )

#### INITIALIZE ####
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#### PACKAGES ####
source("../functions.R")
library(readxl)
library(lubridate)

#### convert files from xlsx to tsv and save to repo ####
###### Helper: strip ALL embedded CR/LF characters inside text cells ######
strip_newlines <- function(df) {
  df %>%
    mutate(across(where(is.character),
                  ~ str_replace_all(.x, "[\r\n]+", " ") |> str_squish()))
}

remove_empty_enhanced <- function(dat, 
                                  which = c("rows", "cols"), 
                                  quiet = FALSE,
                                  exclude_cols = NULL) {
    
    # Validate inputs
    if (!is.data.frame(dat)) {
        stop("Input must be a data frame")
    }
    
    which <- match.arg(which, c("rows", "cols"), several.ok = TRUE)
    
    original_rows <- nrow(dat)
    original_cols <- ncol(dat)
    result <- dat
    
    # Helper function to check if a value is empty
    # Handles different data types appropriately
    is_empty_value <- function(x) {
        if (is.null(x)) return(TRUE)
        if (length(x) == 0) return(TRUE)
        if (all(is.na(x))) return(TRUE)
        
        # For character/factor types, also check for empty strings
        if (is.character(x) || is.factor(x)) {
            x_char <- as.character(x)
            return(all(is.na(x_char) | x_char == ""))
        }
        
        # For other types (numeric, Date, POSIXct, etc.), only NA counts as empty
        return(FALSE)
    }
    
    # Remove empty rows
    if ("rows" %in% which) {
        # Identify rows that are completely empty
        empty_rows <- apply(result, 1, function(row) {
            all(sapply(row, function(val) {
                if (is.na(val)) return(TRUE)
                if (is.character(val) && val == "") return(TRUE)
                if (is.factor(val) && as.character(val) == "") return(TRUE)
                return(FALSE)
            }))
        })
        
        rows_to_remove <- sum(empty_rows)
        
        if (rows_to_remove > 0) {
            result <- result[!empty_rows, , drop = FALSE]
            
            if (!quiet) {
                message(sprintf("Removed %d empty row%s.", 
                                rows_to_remove,
                                ifelse(rows_to_remove == 1, "", "s")))
            }
        }
    }
    
    # Remove empty columns
    if ("cols" %in% which) {
        # Identify columns that are completely empty
        empty_cols <- logical(ncol(result))
        names(empty_cols) <- names(result)
        
        for (i in seq_along(result)) {
            col_name <- names(result)[i]
            empty_cols[i] <- is_empty_value(result[[i]])
        }
        
        # Exclude specified columns from removal
        if (!is.null(exclude_cols) && length(exclude_cols) > 0) {
            # Only consider columns that actually exist in the data
            cols_to_exclude <- intersect(exclude_cols, names(result))
            
            if (length(cols_to_exclude) > 0) {
                # Track which excluded columns were actually empty
                excluded_empty <- character(0)
                
                for (col in cols_to_exclude) {
                    if (empty_cols[col]) {
                        excluded_empty <- c(excluded_empty, col)
                        # Mark this column as not empty so it won't be removed
                        empty_cols[col] <- FALSE
                    }
                }
                
                if (!quiet && length(excluded_empty) > 0) {
                    message(sprintf("Kept %d empty column%s due to exclusion: %s",
                                    length(excluded_empty),
                                    ifelse(length(excluded_empty) == 1, "", "s"),
                                    paste(excluded_empty, collapse = ", ")))
                }
            }
        }
        
        cols_to_remove <- sum(empty_cols)
        
        if (cols_to_remove > 0) {
            # Get names of columns to be removed for reporting
            removed_col_names <- names(empty_cols)[empty_cols]
            
            cols_to_keep <- !empty_cols
            result <- result[, cols_to_keep, drop = FALSE]
            
            if (!quiet) {
                message(sprintf("Removed %d empty column%s: %s", 
                                cols_to_remove,
                                ifelse(cols_to_remove == 1, "", "s"),
                                paste(removed_col_names, collapse = ", ")))
            }
        }
    }
    
    # Reset row names if rows were removed
    if ("rows" %in% which && nrow(result) < original_rows) {
        rownames(result) <- NULL
    }
    
    return(result)
}




purrr::walk2(excel_files, dest_dirs, function(fname, ddir) {
  # Construct full paths
  in_path  <- file.path(onedrive_path, fname)
  out_path <- file.path(ddir, str_replace(fname, "\\.xlsx$", "_onedrive.tsv")) %>%
      str_to_lower()
  
  # Create destination directory if it doesn't exist
  if (!dir.exists(ddir)) dir.create(ddir, recursive = TRUE)
  
  # Read the first sheet of the workbook and write as TSV
  in_file <- read_excel(in_path, 
                        na = c('', 'NA', 'N/A', '?'),
                        guess_max = 1e6) %>%
      remove_empty_enhanced(exclude_cols = 'Field_ID', 
                            which = c('rows', 'cols'), 
                            quiet = FALSE) %>%
      strip_newlines() 
  
  
  if(fname == "Individual_sheet.xlsx"){
      
      suppressWarnings(
          #Warnings are known and related to parsing the dates not something to pay attention to
          processed_file <- mutate(in_file,
                                   Species_ID_date = case_when(str_detect(Species_ID_date, "^[0-9]{5}$") ~ as.integer(Species_ID_date) |> 
                                                                   as.Date(origin = as.Date("1899-12-30")) %>% as.character(),
                                                               TRUE ~ as.character(Species_ID_date))) %>%
              mutate(Species_ID_year = case_when(str_detect(Species_ID_date, "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ mdy(Species_ID_date) %>% year(), 
                                                 str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}[/-][0-9]{1,2}$") ~ ymd(Species_ID_date) %>% year(), 
                                                 str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}$") ~ str_c(Species_ID_date, '/', '01') %>% ymd() %>% year(), 
                                                 str_detect(Species_ID_date, "^[0-9]{4}$") ~ as.integer(Species_ID_date),
                                                 str_detect(Species_ID_date,
                                                            "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}-[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ 
                                                     str_extract(Species_ID_date, "[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") %>%
                                                     mdy() %>% year(), 
                                                 TRUE ~ NA_integer_),
                     Species_ID_month = case_when(str_detect(Species_ID_date, "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ mdy(Species_ID_date) %>% month(), 
                                                  str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}[/-][0-9]{1,2}$") ~ ymd(Species_ID_date) %>% month(), 
                                                  str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}$") ~ str_c(Species_ID_date, '/', '01') %>% ymd() %>% month(), 
                                                  str_detect(Species_ID_date, "^[0-9]{4}$") ~ NA_integer_,
                                                  str_detect(Species_ID_date,
                                                             "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}-[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ 
                                                      str_extract(Species_ID_date, "[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") %>%
                                                      mdy() %>% month(), 
                                                  TRUE ~ NA_integer_),
                     Species_ID_day = case_when(str_detect(Species_ID_date, "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ mdy(Species_ID_date) %>% day(), 
                                                str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}[/-][0-9]{1,2}$") ~ ymd(Species_ID_date) %>% day(), 
                                                str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}$") ~ NA_integer_, 
                                                str_detect(Species_ID_date, "^[0-9]{4}$") ~ NA_integer_,
                                                str_detect(Species_ID_date,
                                                           "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}-[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ 
                                                    str_extract(Species_ID_date, "[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") %>%
                                                    mdy() %>% day(), 
                                                TRUE ~ NA_integer_)) %>%
              relocate(Species_ID_date_originallyEntered = Species_ID_date,
                       .after = everything())
      )
      
      
  } else {
      processed_file <- in_file
  }
  
  processed_file <- processed_file %>%
      distinct() %>%
      rename_with(~str_to_lower(.x)) %>%
      mutate(across(matches("filter_out_this_row"), ~replace_na(., FALSE))) %>%
      filter(if_any(matches("filter_out_this_row"), ~!.)) %>%
      select(-matches('filter_out_this_row'))
  
  
  write_tsv(processed_file, out_path, eol = "\n")
  
  message("✅ Wrote ", out_path)
})

