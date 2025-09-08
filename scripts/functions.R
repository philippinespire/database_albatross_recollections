#### install_and_load_functions ####
here::i_am("scripts/functions.R")

#### Libraries Used Throughout ####
suppressPackageStartupMessages(library(dm))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(tibble))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(janitor))

#### Compile Database Files ####
#### Function to Apply Corrections ####
#Apply corrections to input data
.apply_corrections <- function(data, file_type, verbose = FALSE) {
    
    
    corrections <- read_csv(here::here("db_files", "extractions_mislabelling_sheet.csv"),
                            show_col_types = FALSE) %>%
        clean_names() %>% 
        # Remove any completely empty rows
        filter(!if_all(everything(), is.na))
    
    if (is.null(corrections) || nrow(corrections) == 0) {
        if (verbose) message("No corrections to apply")
        return(data)
    }
    
    # Ensure column names are lowercase
    data <- data %>%
        rename_with(~str_to_lower(.x))
    
    # Add tracking columns if they don't exist
    if (!"correction_applied" %in% names(data)) {
        data <- data %>%
            mutate(
                correction_applied = FALSE,
                correction_id = NA_character_,
                correction_details = NA_character_,
                correction_date = NA_character_
            )
    }
    
    corrections_applied <- 0
    
    if (file_type == "dna_extractions_sheets") {
        
        for (i in seq_len(nrow(corrections))) {
            correction <- corrections[i, ]
            
            # Find matching rows
            matching_rows <- rep(FALSE, nrow(data))
            
            if (!is.na(correction$original_extraction_id) && !is.na(correction$original_individual_id)) {
                matching_rows <- (data$extraction_id == correction$original_extraction_id) & 
                    (data$individual_id == correction$original_individual_id)
                matching_rows[is.na(matching_rows)] <- FALSE
            } else if (!is.na(correction$original_extraction_id)) {
                matching_rows <- data$extraction_id == correction$original_extraction_id
                matching_rows[is.na(matching_rows)] <- FALSE
            } else if (!is.na(correction$original_individual_id)) {
                matching_rows <- data$individual_id == correction$original_individual_id
                matching_rows[is.na(matching_rows)] <- FALSE
            }
            
            if (any(matching_rows)) {
                changes <- c()
                
                # Update extraction_id ONLY if it's different
                if (!is.na(correction$corrected_extraction_id) && 
                    !is.na(correction$original_extraction_id) &&
                    correction$corrected_extraction_id != correction$original_extraction_id) {
                    data[matching_rows, "extraction_id"] <- correction$corrected_extraction_id
                    changes <- c(changes, sprintf("extraction_id: %s->%s", 
                                                  correction$original_extraction_id,
                                                  correction$corrected_extraction_id))
                }
                
                # Update individual_id ONLY if it's different
                if (!is.na(correction$corrected_individual_id) && 
                    !is.na(correction$original_individual_id) &&
                    correction$corrected_individual_id != correction$original_individual_id) {
                    data[matching_rows, "individual_id"] <- correction$corrected_individual_id
                    changes <- c(changes, sprintf("individual_id: %s->%s", 
                                                  correction$original_individual_id,
                                                  correction$corrected_individual_id))
                }
                
                # Update plateid ONLY if it's different
                if ("plateid" %in% names(data) &&
                    !is.na(correction$corrected_extraction_plate_id) && 
                    !is.na(correction$original_extraction_plate_id) &&
                    correction$corrected_extraction_plate_id != correction$original_extraction_plate_id) {
                    data[matching_rows, "plateid"] <- correction$corrected_extraction_plate_id
                    changes <- c(changes, sprintf("plateid: %s->%s", 
                                                  correction$original_extraction_plate_id,
                                                  correction$corrected_extraction_plate_id))
                }
                
                # Only update tracking columns if there were actual changes
                if (length(changes) > 0) {
                    data[matching_rows, "correction_applied"] <- TRUE
                    data[matching_rows, "correction_id"] <- correction$misidentification_id
                    data[matching_rows, "correction_details"] <- paste(changes, collapse = "; ")
                    data[matching_rows, "correction_date"] <- as.character(correction$date_issue_identified)
                    
                    corrections_applied <- corrections_applied + sum(matching_rows)
                    if (verbose) {
                        message(sprintf("Applied correction %s to %d rows", 
                                        correction$misidentification_id, sum(matching_rows)))
                    }
                }
            }
        }
        
        if (verbose) {
            message(sprintf("Total corrections applied to %s: %d rows", 
                            file_type, corrections_applied))
        }
    }
    
    if (file_type == "individuals_sheets") {
        
        for (i in seq_len(nrow(corrections))) {
            correction <- corrections[i, ]
            
            matching_rows <- rep(FALSE, nrow(data))
            
            if (!is.na(correction$original_individual_id) && !is.na(correction$original_lot_id)) {
                matching_rows <- (data$individual_id == correction$original_individual_id) & 
                    (data$lot_id == correction$original_lot_id)
                matching_rows[is.na(matching_rows)] <- FALSE
            } else if (!is.na(correction$original_individual_id)) {
                matching_rows <- data$individual_id == correction$original_individual_id
                matching_rows[is.na(matching_rows)] <- FALSE
            }
            
            if (any(matching_rows)) {
                changes <- c()
                
                # Update individual_id ONLY if it's different
                if (!is.na(correction$corrected_individual_id) && 
                    !is.na(correction$original_individual_id) &&
                    correction$corrected_individual_id != correction$original_individual_id) {
                    data[matching_rows, "individual_id"] <- correction$corrected_individual_id
                    changes <- c(changes, sprintf("individual_id: %s->%s", 
                                                  correction$original_individual_id,
                                                  correction$corrected_individual_id))
                }
                
                # Update lot_id ONLY if it's different
                if (!is.na(correction$corrected_lot_id) && 
                    !is.na(correction$original_lot_id) &&
                    correction$corrected_lot_id != correction$original_lot_id) {
                    data[matching_rows, "lot_id"] <- correction$corrected_lot_id
                    changes <- c(changes, sprintf("lot_id: %s->%s", 
                                                  correction$original_lot_id,
                                                  correction$corrected_lot_id))
                }
                
                # Only update tracking columns if there were actual changes
                if (length(changes) > 0) {
                    data[matching_rows, "correction_applied"] <- TRUE
                    data[matching_rows, "correction_id"] <- correction$misidentification_id
                    data[matching_rows, "correction_details"] <- paste(changes, collapse = "; ")
                    data[matching_rows, "correction_date"] <- as.character(correction$date_issue_identified)
                    
                    corrections_applied <- corrections_applied + sum(matching_rows)
                    if (verbose) {
                        message(sprintf("Applied correction %s to %d rows", 
                                        correction$misidentification_id, sum(matching_rows)))
                    }
                }
            }
        }
        
        if (verbose) {
            message(sprintf("Total corrections applied to %s: %d rows", 
                            file_type, corrections_applied))
        }
    }
    
    if (file_type == "lots_sheets") {
        
        for (i in seq_len(nrow(corrections))) {
            correction <- corrections[i, ]
            
            matching_rows <- rep(FALSE, nrow(data))
            
            if (!is.na(correction$original_lot_id)) {
                matching_rows <- data$lot_id == correction$original_lot_id
                matching_rows[is.na(matching_rows)] <- FALSE
            }
            
            if (any(matching_rows)) {
                changes <- c()
                
                # Update lot_id ONLY if it's different
                if (!is.na(correction$corrected_lot_id) && 
                    !is.na(correction$original_lot_id) &&
                    correction$corrected_lot_id != correction$original_lot_id) {
                    data[matching_rows, "lot_id"] <- correction$corrected_lot_id
                    changes <- c(changes, sprintf("lot_id: %s->%s", 
                                                  correction$original_lot_id,
                                                  correction$corrected_lot_id))
                }
                
                # Only update tracking columns if there were actual changes
                if (length(changes) > 0) {
                    data[matching_rows, "correction_applied"] <- TRUE
                    data[matching_rows, "correction_id"] <- correction$misidentification_id
                    data[matching_rows, "correction_details"] <- paste(changes, collapse = "; ")
                    data[matching_rows, "correction_date"] <- as.character(correction$date_issue_identified)
                    
                    corrections_applied <- corrections_applied + sum(matching_rows)
                    if (verbose) {
                        message(sprintf("Applied correction %s to %d rows", 
                                        correction$misidentification_id, sum(matching_rows)))
                    }
                }
            }
        }
        
        if (verbose) {
            message(sprintf("Total corrections applied to %s: %d rows", 
                            file_type, corrections_applied))
        }
    }
    
    return(data)
}

#' Harmonize column types across multiple data frames for safe binding
#'
#' @param df_list List of data frames to harmonize
#' @return List of data frames with consistent column types
.harmonize_column_types <- function(df_list) {
    # Get all unique column names across all dataframes
    all_cols <- unique(unlist(lapply(df_list, names)))
    
    # For each column, determine the most inclusive type needed
    col_types <- list()
    
    for (col in all_cols) {
        types_present <- character()
        
        # Collect all types for this column across all dataframes
        for (df in df_list) {
            if (col %in% names(df)) {
                types_present <- c(types_present, class(df[[col]])[1])
            }
        }
        
        # Determine the most inclusive type
        # Priority: character > numeric > integer > logical
        if ("character" %in% types_present) {
            col_types[[col]] <- "character"
        } else if ("numeric" %in% types_present || "double" %in% types_present) {
            col_types[[col]] <- "numeric"
        } else if ("integer" %in% types_present) {
            # Check if any integers are too large or if we have NAs that need numeric
            needs_numeric <- FALSE
            for (df in df_list) {
                if (col %in% names(df) && "integer" %in% class(df[[col]])) {
                    if (any(is.na(df[[col]])) || any(df[[col]] > .Machine$integer.max, na.rm = TRUE)) {
                        needs_numeric <- TRUE
                        break
                    }
                }
            }
            col_types[[col]] <- if (needs_numeric) "numeric" else "integer"
        } else if ("Date" %in% types_present || "POSIXct" %in% types_present) {
            col_types[[col]] <- "character"  # Safest for dates to preserve format
        } else if ("logical" %in% types_present) {
            col_types[[col]] <- "logical"
        } else {
            col_types[[col]] <- "character"  # Default fallback
        }
    }
    
    # Apply the type conversions to each dataframe
    harmonized_list <- list()
    
    for (i in seq_along(df_list)) {
        df <- df_list[[i]]
        
        for (col in names(df)) {
            target_type <- col_types[[col]]
            current_type <- class(df[[col]])[1]
            
            if (current_type != target_type) {
                if (target_type == "character") {
                    df[[col]] <- as.character(df[[col]])
                } else if (target_type == "numeric") {
                    df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
                } else if (target_type == "integer") {
                    df[[col]] <- suppressWarnings(as.integer(df[[col]]))
                } else if (target_type == "logical") {
                    df[[col]] <- as.logical(df[[col]])
                }
            }
        }
        
        harmonized_list[[i]] <- df
    }
    
    return(harmonized_list)
}

# Compile database for use
.compile_db_inputs <- function(verbose = FALSE){
    
    list.files(here::here("db_files"), 
               pattern = 'tsv$',
               full.names = TRUE, 
               recursive = TRUE) %>%
        tibble(file = .) %>%
        mutate(file_type = dirname(file) %>%
                   str_remove('^.*/db_files/')) %>%
        rowwise %>%
        mutate(sheet = read_delim(file, 
                                  delim = '\t', 
                                  show_col_types = FALSE, 
                                  na = c("", "NA", "None"),
                                  id = str_c(file_type, 'file_path'),
                                  guess_max = 1e6) %>%
                   list()) %>%
        ungroup %>%
        summarise(sheet = .harmonize_column_types(sheet) %>%
                      bind_rows() %>%
                      list(),
                  .by = file_type) %>%
        rowwise %>%
        mutate(sheet = .apply_corrections(sheet, file_type, verbose) %>%
                   list()) %>%
        ungroup %>%
        mutate(sheet = set_names(sheet, file_type)) %>%
        pull(sheet)
}

#### Assemble Database ####
.database_assembly <- function(){
    
    db_with_pk <- .compile_db_inputs() %>% #names()
        do.call(dm, .) %>%
        dm::dm_add_pk(sampling_sites_sheets,
                      columns = c(lot_id)) %>%
        dm::dm_add_pk(lots_sheets,
                      columns = c(lot_id)) %>%
        dm::dm_add_pk(individuals_sheets,
                      columns = c(individual_id)) %>%
        dm::dm_add_pk(table = species_sheets,
                      columns = species_valid_name) %>%
        dm::dm_add_pk(dna_extractions_sheets,
                      columns = c(extraction_id)) %>%
        dm::dm_add_pk(table = dna_extractions_gels,
                      columns = gel_id) %>%
        dm::dm_add_pk(shipments_sheets,
                      columns = c(shipment_id, plate_box_id)) %>%
        dm::dm_add_pk(sequence_info_sheets,
                      columns = c(sequencing_batch_id)) %>%
        identity()
    
    db_with_pk %>%
        dm_add_fk(table = lots_sheets, 
                  columns = lot_id, 
                  ref_table = sampling_sites_sheets,
                  ref_columns = lot_id) %>%
        dm_add_fk(table = individuals_sheets, 
                  columns = lot_id, 
                  ref_table = lots_sheets) %>%
        dm_add_fk(table = individuals_sheets, 
                  columns = lot_id, 
                  ref_table = sampling_sites_sheets) %>%
        dm_add_fk(table = individuals_sheets,
                  columns = species_valid_name,
                  ref_table = species_sheets,
                  ref_columns = species_valid_name) %>%
        dm_add_fk(table = dna_extractions_sheets, 
                  columns = individual_id, 
                  ref_table = individuals_sheets)
}

#### Database Validation ####
#' Initialize staging folder structure
#'
#' Creates staging folders for each database table type if they don't exist
#' @param base_path Base path for the project (uses here() by default)
#' @return Invisible NULL
.initialize_staging_folders <- function(base_path = here::here()) {
    staging_path <- file.path(base_path, "staging")
    
    # Define expected table types based on your database structure
    table_types <- c(
        "dna_extractions_sheets",
        "dna_extractions_gels", 
        "individuals_sheets",
        "lots_sheets",
        "sampling_sites_sheets",
        "sequence_info_sheets",
        "shipments_sheets",
        "species_sheets"
    )
    
    # Create main staging folder
    if (!dir.exists(staging_path)) {
        dir.create(staging_path)
        cli_alert_success("Created main staging folder")
    }
    
    # Create subfolders for each table type
    for (table_type in table_types) {
        subfolder <- file.path(staging_path, table_type)
        if (!dir.exists(subfolder)) {
            dir.create(subfolder)
        }
    }
    
    # Create a validation_logs folder
    log_path <- file.path(staging_path, "validation_logs")
    if (!dir.exists(log_path)) {
        dir.create(log_path)
    }
    
    cli_alert_success("Staging folders initialized")
    cli_alert_info(paste0("Place TSV files in: ", staging_path, "/<table_type>/"))
    
    invisible(NULL)
}

#' Get current database state
#'
#' Loads the current database using existing functions
#' @return dm object with current database
#' @export
get_database <- function() {
    db <- .database_assembly()
    return(db)
}

#' Create augmented database with staging files
#'
#' Creates a temporary database that includes both existing data and new staging data
#' @param db Current database dm object
#' @param staging_data_list List of staging data frames by table type
#' @return Augmented dm object
.create_augmented_database <- function(db, staging_data_list) {
    augmented_db <- db
    
    for (table_type in names(staging_data_list)) {
        if (table_type %in% names(dm_get_tables(db))) {
            # Combine existing table with staging data
            existing_data <- db %>% 
                dm_get_tables() %>%
                pluck(table_type)
            
            new_data <- pluck(staging_data_list, table_type)
            
            # Ensure columns match
            common_cols <- intersect(names(existing_data), names(new_data))
            
            # Align data types before combining
            for (col in common_cols) {
                existing_type <- class(existing_data[[col]])[1]
                new_type <- class(new_data[[col]])[1]
                
                if (existing_type != new_type) {
                    # Try to convert new data to match existing type
                    if (existing_type == "numeric" || existing_type == "integer") {
                        new_data[[col]] <- suppressWarnings(as.numeric(new_data[[col]]))
                    } else if (existing_type == "character") {
                        new_data[[col]] <- as.character(new_data[[col]])
                    } else if (existing_type == "logical") {
                        new_data[[col]] <- as.logical(new_data[[col]])
                    } else if (existing_type == "Date") {
                        new_data[[col]] <- as.Date(new_data[[col]])
                    }
                }
            }
            
            combined_data <- bind_rows(
                existing_data %>% select(all_of(common_cols)),
                new_data %>% select(all_of(common_cols))
            )
            
            # Update the table in augmented database
            augmented_db <- augmented_db %>%
                dm_select_tbl(-!!sym(table_type)) %>%
                dm(!!table_type := combined_data, .)
        }
    }
    
    return(augmented_db)
}

#' Validate TSV file structure and content
#'
#' @param new_data Data frame already read from TSV file
#' @param file_path Path to TSV file (for reference/reporting)
#' @param table_type Type of table (e.g., "individuals_sheets")
#' @param db Current database dm object
#' @param other_staging_data List of data from other staging files
#' @return List with validation results
.validate_tsv_file <- function(new_data, file_path, table_type, db, other_staging_data = NULL) {
    cli_h2(paste("Validating:", str_c(table_type, basename(file_path), sep = '/')))
    
    validation_result <- list(file = file_path,
                              table_type = table_type,
                              passed = FALSE,
                              errors = list(),
                              warnings = list(),
                              data = new_data)
    
    # Get existing table structure if it exists
    if (table_type %in% names(dm_get_tables(db))) {
        existing_table <- db %>% 
            dm_get_tables() %>%
            pluck(table_type)
    } else {
        validation_result$errors$table_not_found <- paste("Table type", table_type, "not found in database")
        return(validation_result)
    }
    
    # Create augmented database if other staging data exists
    augmented_db <- db
    if (!is.null(other_staging_data) && length(other_staging_data) > 0) {
        augmented_db <- .create_augmented_database(db, other_staging_data)
    }
    
    # Get primary and foreign key information
    pk_info <- dm_get_all_pks(db) %>%
        filter(table == table_type)
    
    fk_info <- dm_get_all_fks(db) %>%
        filter(child_table == table_type)
    
    # Run validation checks
    cli_progress_step("Checking column structure...")
    column_check <- .check_column_structure(new_data, existing_table, table_type)
    if (column_check$status == "FAIL") {
        validation_result$errors$columns <- column_check
    } else if (column_check$status == "WARNING") {
        validation_result$warnings$columns <- column_check
    }
    
    # Check primary keys if they exist
    if (nrow(pk_info) > 0) {
        pk_cols <- unlist(pk_info$pk_col)
        
        cli_progress_step("Checking for missing primary keys...")
        missing_pk_check <- .check_missing_primary_keys(new_data, pk_cols, table_type)
        if (missing_pk_check$status == "FAIL") {
            validation_result$errors$missing_pks <- missing_pk_check
        }
        
        cli_progress_step("Checking for duplicate primary keys...")
        # Use augmented database for duplicate check
        augmented_table <- augmented_db %>% 
            dm_get_tables() %>%
            pluck(table_type)
        dup_pk_check <- .check_duplicate_primary_keys(new_data, augmented_table, pk_cols, table_type)
        if (dup_pk_check$status == "FAIL") {
            validation_result$errors$duplicate_pks <- dup_pk_check
        }
    }
    
    # Check foreign keys if they exist - use augmented database
    if (nrow(fk_info) > 0) {
        cli_progress_step("Checking foreign key constraints...")
        
        for (i in 1:nrow(fk_info)) {
            fk <- fk_info[i,]
            parent_table <- augmented_db %>% 
                dm_get_tables() %>% 
                pluck(fk$parent_table)
            
            fk_check <- .check_foreign_keys(
                new_data,
                parent_table,
                unlist(fk$child_fk_cols),
                unlist(fk$parent_key_cols),
                table_type,
                fk$parent_table
            )
            
            if (fk_check$status == "FAIL") {
                fk_name <- paste0("fk_to_", fk$parent_table)
                validation_result$errors[[fk_name]] <- fk_check
            }
        }
    }
    
    # Check data quality
    cli_progress_step("Checking data quality...")
    quality_check <- .check_data_quality_comprehensive(new_data, pk_cols, table_type)
    if (quality_check$status == "WARNING") {
        validation_result$warnings$quality <- quality_check
    } else if (quality_check$status == "FAIL") {
        validation_result$errors$quality <- quality_check
    }
    
    # Table-specific validations - use augmented database
    cli_progress_step("Running table-specific validations...")
    specific_check <- .run_table_specific_checks(new_data, table_type, augmented_db)
    if (specific_check$status == "FAIL") {
        validation_result$errors$specific <- specific_check
    } else if (specific_check$status == "WARNING") {
        validation_result$warnings$specific <- specific_check
    }
    
    # Determine if validation passed
    validation_result$passed <- length(validation_result$errors) == 0
    
    return(validation_result)
}

#' Check column structure
#'
#' @param new_data New data frame
#' @param existing_table Existing table structure
#' @param table_type Table name
#' @return Validation result list
.check_column_structure <- function(new_data, existing_table, table_type) {
    result <- list(status = "PASS", issues = NULL, guidance = NULL)
    
    expected_cols <- names(existing_table)
    actual_cols <- names(new_data)
    
    missing_cols <- setdiff(expected_cols, actual_cols)
    extra_cols <- setdiff(actual_cols, expected_cols)
    
    # Remove correction tracking columns from missing cols check
    correction_cols <- c("correction_applied", "correction_id", "correction_details", "correction_date")
    missing_cols <- setdiff(missing_cols, correction_cols)
    
    # Remove filepath columns from missing cols check
    filepath_cols <- paste0(table_type, 'file_path')
    missing_cols <- setdiff(missing_cols, filepath_cols)
    
    if (length(missing_cols) > 0) {
        result$status <- "FAIL"
        result$issues$missing <- missing_cols
        result$guidance <- paste0(
            "Missing required columns in ", table_type, ":\n",
            paste("  -", missing_cols, collapse = "\n"),
            "\n\nFix: Add these columns to your TSV file with appropriate data"
        )
    }
    
    if (length(extra_cols) > 0) {
        if (result$status != "FAIL") result$status <- "WARNING"
        result$issues$extra <- extra_cols
        if (is.null(result$guidance)) result$guidance <- ""
        result$guidance <- paste0(result$guidance,
                                  "\nExtra columns found (will be removed):\n",
                                  paste("  -", extra_cols, collapse = "\n")
        )
    }
    
    return(result)
}

#' Check for missing primary keys
#'
#' @param data Data frame to check
#' @param pk_cols Primary key columns
#' @param table_type Table name
#' @return Validation result list
.check_missing_primary_keys <- function(data, pk_cols, table_type) {
    result <- list(status = "PASS", issues = NULL, guidance = NULL)
    
    missing_pk_rows <- data %>%
        mutate(row_number = row_number()) %>%
        filter(if_any(all_of(pk_cols), is.na))
    
    if (nrow(missing_pk_rows) > 0) {
        result$status <- "FAIL"
        result$issues <- missing_pk_rows
        
        na_summary <- pk_cols %>%
            map_chr(~paste0(.x, ": ", sum(is.na(missing_pk_rows[[.x]])), " NAs")) %>%
            paste(collapse = ", ")
        
        result$guidance <- paste0(
            "Found ", nrow(missing_pk_rows), " rows with missing primary key values in ", table_type, "\n",
            "Rows with issues: ", paste(head(missing_pk_rows$row_number, 20), collapse = ", "),
            ifelse(nrow(missing_pk_rows) > 20, "...", ""), "\n",
            "Missing values: ", na_summary,
            "\n\nFix in your TSV file:\n",
            "1. Check rows ", paste(range(missing_pk_rows$row_number), collapse = "-"), "\n",
            "2. Fill in missing values for: ", paste(pk_cols, collapse = ", "), "\n",
            "3. Ensure every row has complete primary key information"
        )
    }
    
    return(result)
}

#' Check for duplicate primary keys
#'
#' @param new_data New data frame
#' @param existing_table Existing table (may include other staging data)
#' @param pk_cols Primary key columns
#' @param table_type Table name
#' @return Validation result list
.check_duplicate_primary_keys <- function(new_data, existing_table, pk_cols, table_type) {
    result <- list(status = "PASS", issues = NULL, guidance = NULL)
    
    # Check for duplicates within new data
    internal_dups <- new_data %>%
        filter(!if_any(all_of(pk_cols), is.na)) %>%
        group_by(across(all_of(pk_cols))) %>%
        filter(n() > 1) %>%
        ungroup() %>%
        mutate(row_number = row_number())
    
    # Check for duplicates with existing data
    new_keys <- new_data %>%
        filter(!if_any(all_of(pk_cols), is.na)) %>%
        select(all_of(pk_cols)) %>%
        distinct()
    
    existing_keys <- existing_table %>%
        select(all_of(pk_cols)) %>%
        distinct()
    
    conflicting_keys <- inner_join(new_keys, existing_keys, by = pk_cols)
    
    if (nrow(internal_dups) > 0 || nrow(conflicting_keys) > 0) {
        result$status <- "FAIL"
        result$issues <- list(
            internal = internal_dups,
            conflicts = conflicting_keys
        )
        
        guidance <- paste0("Duplicate primary key issues in ", table_type, ":\n\n")
        
        if (nrow(internal_dups) > 0) {
            dup_summary <- internal_dups %>%
                select(all_of(pk_cols)) %>%
                distinct() %>%
                unite("key", all_of(pk_cols), sep = " | ") %>%
                head(10)
            
            guidance <- paste0(guidance,
                               "Duplicates within your file:\n",
                               paste("  -", dup_summary$key, collapse = "\n"),
                               ifelse(nrow(dup_summary) == 10, "\n  ... and more", ""),
                               "\n\nFix: Remove or modify duplicate rows in your TSV\n\n"
            )
        }
        
        if (nrow(conflicting_keys) > 0) {
            conflict_summary <- conflicting_keys %>%
                unite("key", all_of(pk_cols), sep = " | ") %>%
                head(10)
            
            guidance <- paste0(guidance,
                               "Keys that already exist in database:\n",
                               paste("  -", conflict_summary$key, collapse = "\n"),
                               ifelse(nrow(conflict_summary) == 10, "\n  ... and more", ""),
                               "\n\nFix: These records already exist. Either:\n",
                               "  1. Remove these rows if they're duplicates\n",
                               "  2. Update the keys if these are new records\n"
            )
        }
        
        result$guidance <- guidance
    }
    
    return(result)
}

#' Check foreign key constraints
#'
#' @param child_data Child table data
#' @param parent_data Parent table data (may include other staging data)
#' @param fk_cols Foreign key columns
#' @param pk_cols Parent primary key columns
#' @param child_name Child table name
#' @param parent_name Parent table name
#' @return Validation result list
.check_foreign_keys <- function(child_data, parent_data, fk_cols, pk_cols, 
                                child_name, parent_name) {
    result <- list(status = "PASS", issues = NULL, guidance = NULL)
    
    # Get non-NA foreign keys from child
    child_keys <- child_data %>%
        filter(!if_any(all_of(fk_cols), is.na)) %>%
        select(all_of(fk_cols)) %>%
        distinct()
    
    # Get all primary keys from parent (including staging data)
    parent_keys <- parent_data %>%
        select(all_of(pk_cols)) %>%
        distinct()
    
    # Find orphaned keys
    orphaned <- anti_join(child_keys, parent_keys, by = setNames(pk_cols, fk_cols))
    
    if (nrow(orphaned) > 0) {
        result$status <- "FAIL"
        result$issues <- orphaned
        
        orphaned_summary <- orphaned %>%
            unite("key", all_of(fk_cols), sep = " | ") %>%
            head(20)
        
        result$guidance <- paste0(
            "Foreign key constraint violation in ", child_name, ":\n",
            "References to non-existent records in ", parent_name, ":\n",
            paste("  -", orphaned_summary$key, collapse = "\n"),
            ifelse(nrow(orphaned) > 20, paste0("\n  ... and ", nrow(orphaned) - 20, " more"), ""),
            "\n\nFix options:\n",
            "1. Correct the ", paste(fk_cols, collapse = ", "), " values in your TSV\n",
            "2. Ensure the parent records are in the staging folder or database\n",
            "3. Remove these rows if they're invalid"
        )
    }
    
    return(result)
}

#' Check data quality comprehensively
#'
#' @param data Data frame to check
#' @param pk_cols Primary key columns (can be NULL)
#' @param table_type Table name
#' @return Validation result list
.check_data_quality_comprehensive <- function(data, pk_cols = NULL, table_type) {
    result <- list(status = "PASS", issues = list(), guidance = "")
    
    # Check for completely empty rows
    empty_rows <- data %>%
        mutate(row_number = row_number()) %>%
        filter(if_all(everything(), ~is.na(.x) | .x == ""))
    
    if (nrow(empty_rows) > 0) {
        result$status <- "WARNING"
        result$issues$empty_rows <- empty_rows$row_number
        result$guidance <- paste0(result$guidance,
                                  "Empty rows found: ", paste(head(empty_rows$row_number, 10), collapse = ", "),
                                  "\nThese will be removed during import.\n\n"
        )
    }
    
    # Check for unexpected values in key columns
    if (!is.null(pk_cols)) {
        for (col in pk_cols) {
            if (col %in% names(data) && is.character(data[[col]])) {
                # Check for whitespace issues
                ws_rows <- which(data[[col]] != str_trim(data[[col]]))
                if (length(ws_rows) > 0) {
                    result$status <- "WARNING"
                    result$issues[[paste0(col, "_whitespace")]] <- ws_rows
                    result$guidance <- paste0(result$guidance,
                                              "Column '", col, "' has leading/trailing whitespace in rows: ",
                                              paste(head(ws_rows, 10), collapse = ", "), "\n"
                    )
                }
                
                # Check for special characters that might cause issues
                special_char_rows <- which(str_detect(data[[col]], "[<>\"'\\\\]"))
                if (length(special_char_rows) > 0) {
                    result$status <- "WARNING"
                    result$issues[[paste0(col, "_special_chars")]] <- special_char_rows
                    result$guidance <- paste0(result$guidance,
                                              "Column '", col, "' has special characters in rows: ",
                                              paste(head(special_char_rows, 10), collapse = ", "), "\n"
                    )
                }
            }
        }
    }
    
    if (result$guidance != "") {
        result$guidance <- paste0(
            "Data quality issues in ", table_type, ":\n", 
            result$guidance,
            "\nFix: Clean your data in the TSV file before importing"
        )
    }
    
    return(result)
}

#' Run table-specific validation checks
#'
#' @param data Data frame to validate
#' @param table_type Type of table
#' @param db Current database (may include staging data)
#' @return Validation result list
.run_table_specific_checks <- function(data, table_type, db) {
    result <- list(status = "PASS", issues = NULL, guidance = NULL)
    
    # Add specific checks for each table type
    if (table_type == "individuals_sheets") {
        # Check that species_valid_name exists in species_sheets
        if ("species_valid_name" %in% names(data)) {
            species_table <- db %>% 
                dm_get_tables() %>% 
                pluck("species_sheets")
            
            if (!is.null(species_table)) {
                invalid_species <- setdiff(
                    unique(data$species_valid_name[!is.na(data$species_valid_name)]),
                    unique(species_table$species_valid_name)
                )
                
                if (length(invalid_species) > 0) {
                    result$status <- "FAIL"
                    result$issues$invalid_species <- invalid_species
                    result$guidance <- paste0(
                        "Invalid species names found:\n",
                        paste("  -", head(invalid_species, 10), collapse = "\n"),
                        "\n\nFix: Use valid species names from species_sheets table"
                    )
                }
            }
        }
    }
    
    if (table_type == "dna_extractions_sheets") {
        # Check for valid plate IDs format if present
        if ("plateid" %in% names(data)) {
            invalid_plates <- data %>%
                filter(!is.na(plateid)) %>%
                filter(!str_detect(plateid, "^[A-Za-z0-9_-]+$")) %>%
                pull(plateid) %>%
                unique()
            
            if (length(invalid_plates) > 0) {
                result$status <- "WARNING"
                result$issues$invalid_plate_format <- invalid_plates
                result$guidance <- paste0(
                    "Plate IDs with unusual characters:\n",
                    paste("  -", head(invalid_plates, 5), collapse = "\n"),
                    "\n\nConsider using only letters, numbers, underscores, and hyphens"
                )
            }
        }
    }
    
    return(result)
}

#' Process and integrate validated files
#'
#' @param validation_results List of all validation results
#' @param apply_corrections Whether to apply corrections from extractions_mislabelling_sheet
#' @return Success status
.integrate_validated_files <- function(validation_results, apply_corrections = TRUE) {
    # Check if all files passed
    all_passed <- all(sapply(validation_results, function(x) x$passed))
    
    if (!all_passed) {
        cli_alert_danger("Cannot integrate files - some validations failed")
        return(FALSE)
    }
    
    cli_h3("Integrating validated files")
    
    # Process each file
    for (result in validation_results) {
        file_path <- result$file
        table_type <- result$table_type
        
        cli_progress_step(paste("Processing:", basename(file_path)))
        
        # Apply corrections if needed
        if (apply_corrections) {
            source(here::here("scripts", "functions.R"))
            processed_data <- .apply_corrections(result$data, table_type, verbose = FALSE)
        } else {
            processed_data <- result$data
        }
        
        # Determine destination path
        dest_folder <- here::here("db_files", table_type)
        
        # Generate new filename with timestamp
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        original_name <- tools::file_path_sans_ext(basename(file_path))
        new_filename <- paste0(original_name, "_", timestamp, ".tsv")
        dest_path <- file.path(dest_folder, new_filename)
        
        # Write to destination
        write_tsv(processed_data, dest_path, na = "")
        
        # Archive the staging file
        archive_folder <- file.path(dirname(file_path), "processed")
        if (!dir.exists(archive_folder)) {
            dir.create(archive_folder)
        }
        
        archive_path <- file.path(archive_folder, paste0(original_name, "_processed_", timestamp, ".tsv"))
        file.rename(file_path, archive_path)
        
        cli_alert_success(paste("Integrated:", table_type, "-", basename(new_filename)))
    }
    
    cli_alert_success("All files integrated successfully")
    
    return(TRUE)
}

#' Main validation and integration pipeline
#'
#' @param staging_path Path to staging folder (defaults to here::here("staging"))
#' @param auto_integrate If TRUE, automatically integrate files that pass validation
#' @param save_report If TRUE, save validation report to file
#' @return List of validation results
.validate_staging_files <- function(staging_path = here::here("staging"), 
                                    auto_integrate = FALSE,
                                    save_report = TRUE) {
    
    cli_h1("PIRE Database Staging Validation")
    
    # Initialize staging folders if needed
    if (!dir.exists(staging_path)) {
        .initialize_staging_folders()
        cli_alert_warning("No files found in staging folders. Add TSV files and run again.")
        return(invisible(NULL))
    }
    
    # Get current database
    cli_progress_step("Loading current database...")
    db <- get_database()
    
    # Find all TSV files in staging
    staging_files <- list.files(staging_path,
                                pattern = "\\.tsv$",
                                recursive = TRUE,
                                full.names = TRUE) %>%
        str_subset("/processed/", negate = TRUE) %>%
        str_subset("EXAMPLE", negate = TRUE)
    
    if (length(staging_files) == 0) {
        cli_alert_info("No TSV files found in staging folders")
        return(invisible(NULL))
    }
    
    cli_alert_info(paste("Found", length(staging_files), "file(s) to validate"))
    
    # First pass: Read all staging data
    staging_data_list <- list()
    file_table_map <- list()
    
    for (file in staging_files) {
        table_type <- basename(dirname(file))
        
        # Skip if not a recognized table type
        if (!table_type %in% names(dm_get_tables(db))) {
            cli_alert_warning(paste("Skipping - unknown table type:", table_type))
            next
        }
        
        # Read the file
        tryCatch({
            data <- read_delim(file,
                               delim = '\t',
                               show_col_types = FALSE,
                               na = c("", "NA", "None"),
                               guess_max = 1e6) %>%
                rename_with(~str_to_lower(.x)) %>%
                mutate(across(everything(), ~str_trim(.x)))
            
            # Add to staging data list
            if (table_type %in% names(staging_data_list)) {
                # Combine with existing staging data for this table type
                common_cols <- intersect(names(staging_data_list[[table_type]]), names(data))
                staging_data_list[[table_type]] <- bind_rows(
                    staging_data_list[[table_type]] %>% select(all_of(common_cols)),
                    data %>% select(all_of(common_cols))
                )
            } else {
                staging_data_list[[table_type]] <- data
            }
            
            file_table_map[[file]] <- list(table_type = table_type, data = data)
            
        }, error = function(e) {
            cli_alert_warning(paste("Failed to read", basename(file), ":", e$message))
        })
    }
    
    # Second pass: Validate each file with awareness of all staging data
    all_results <- list()
    
    for (file in names(file_table_map)) {
        table_type <- file_table_map[[file]]$table_type
        file_data <- file_table_map[[file]]$data
        
        # Create other staging data (exclude current file's data)
        other_staging_data <- staging_data_list
        
        # For the current file's table type, exclude this file's data
        if (table_type %in% names(other_staging_data)) {
            # Get staging data for this table type minus current file
            other_files_data <- list()
            for (other_file in names(file_table_map)) {
                if (other_file != file && file_table_map[[other_file]]$table_type == table_type) {
                    other_data <- file_table_map[[other_file]]$data
                    if (length(other_files_data) == 0) {
                        other_files_data <- other_data
                    } else {
                        common_cols <- intersect(names(other_files_data), names(other_data))
                        other_files_data <- bind_rows(
                            other_files_data %>% select(all_of(common_cols)),
                            other_data %>% select(all_of(common_cols))
                        )
                    }
                }
            }
            
            if (length(other_files_data) > 0) {
                other_staging_data[[table_type]] <- other_files_data
            } else {
                other_staging_data[[table_type]] <- NULL
            }
        }
        
        # Validate file with other staging data context
        validation_result <- .validate_tsv_file(file_data, file, table_type, db, other_staging_data)
        all_results[[str_c(table_type, basename(file), sep = '/')]] <- validation_result
        
        # Print results
        .print_validation_result(validation_result)
    }
    
    # Save report if requested
    if (save_report && length(all_results) > 0) {
        .save_validation_report(all_results, staging_path)
    }
    
    # Print summary
    .print_validation_summary_report(all_results)
    
    # Integrate if all passed and auto_integrate is TRUE
    if (auto_integrate) {
        all_passed <- all(sapply(all_results, function(x) x$passed))
        if (all_passed) {
            .integrate_validated_files(all_results)
        }
    }
    
    return(invisible(all_results))
}

#' Print validation result for a single file
#'
#' @param result Validation result object
.print_validation_result <- function(result) {
    file_name <- basename(result$file)
    
    if (result$passed) {
        cli_alert_success(paste(file_name, "- PASSED all validations"))
    } else {
        cli_alert_danger(paste(file_name, "- FAILED validation"))
        
        # Print errors
        for (error_name in names(result$errors)) {
            error <- result$errors[[error_name]]
            if (!is.null(error$guidance)) {
                cli_alert_danger(error$guidance)
            }
        }
    }
    
    # Print warnings
    for (warning_name in names(result$warnings)) {
        warning <- result$warnings[[warning_name]]
        if (!is.null(warning$guidance)) {
            cli_alert_warning(warning$guidance)
        }
    }
    
    cat("\n")
}

#' Print summary of all validation results
#'
#' @param results List of validation results
.print_validation_summary_report <- function(results) {
    if (length(results) == 0) return(invisible(NULL))
    
    cli_h2("Validation Summary")
    
    passed <- sum(sapply(results, function(x) x$passed))
    failed <- length(results) - passed
    
    cli_alert_info(paste("Total files processed:", length(results)))
    
    if (passed > 0) {
        cli_alert_success(paste("Passed validation:", passed))
    }
    
    if (failed > 0) {
        cli_alert_danger(paste("Failed validation:", failed))
        
        cli_h3("Files requiring fixes:")
        for (name in names(results)) {
            if (!results[[name]]$passed) {
                cli_li(name)
            }
        }
    }
    
    if (passed > 0 && failed == 0) {
        cli_alert_info("\nAll files passed! To integrate them, run:")
        cli_code('validate_staging_files(auto_integrate = TRUE)')
    }
}

#' Save validation report to file
#'
#' @param results List of validation results
#' @param staging_path Path to staging folder
.save_validation_report <- function(results, staging_path) {
    log_path <- file.path(staging_path, "validation_logs")
    if (!dir.exists(log_path)) {
        dir.create(log_path)
    }
    
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    report_file <- file.path(log_path, paste0("validation_report_", timestamp, ".txt"))
    
    # Create report content
    report_lines <- c(
        paste("PIRE Database Validation Report"),
        paste("Generated:", Sys.time()),
        paste(rep("=", 60), collapse = ""),
        ""
    )
    
    for (file_name in names(results)) {
        result <- results[[file_name]]
        
        report_lines <- c(report_lines,
                          paste("\nFile:", file_name),
                          paste("Table Type:", result$table_type),
                          paste("Status:", ifelse(result$passed, "PASSED ✓", "FAILED ✗")),
                          ""
        )
        
        if (length(result$errors) > 0) {
            report_lines <- c(report_lines, "ERRORS:")
            for (error_name in names(result$errors)) {
                if (!is.null(result$errors[[error_name]]$guidance)) {
                    report_lines <- c(report_lines, 
                                      paste("  -", result$errors[[error_name]]$guidance))
                }
            }
        }
        
        if (length(result$warnings) > 0) {
            report_lines <- c(report_lines, "WARNINGS:")
            for (warning_name in names(result$warnings)) {
                if (!is.null(result$warnings[[warning_name]]$guidance)) {
                    report_lines <- c(report_lines,
                                      paste("  -", result$warnings[[warning_name]]$guidance))
                }
            }
        }
        
        report_lines <- c(report_lines, paste(rep("-", 40), collapse = ""))
    }
    
    writeLines(report_lines, report_file)
    cli_alert_success(paste("Report saved to:", basename(report_file)))
}


update_database <- function(){
    .validate_staging_files(auto_integrate = TRUE)
}