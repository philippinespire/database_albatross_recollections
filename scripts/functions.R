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
suppressPackageStartupMessages(library(vctrs))

#### Compile Database Files ####
#### Function to Apply Corrections ####
#clone from janitor to not require package
.clean_names <- function(dat, case = "snake", ascii = TRUE, use_make_names = TRUE) {
    # Get the names to clean
    old_names <- names(dat)
    
    # Start with the original names
    new_names <- old_names
    
    # Remove non-ASCII if requested
    if (ascii) {
        new_names <- iconv(new_names, from = "", to = "ASCII//TRANSLIT", sub = "")
    }
    
    # Replace non-alphanumeric characters with underscores
    # But preserve existing underscores
    new_names <- gsub("[^a-zA-Z0-9_]+", "_", new_names)
    
    # For snake_case conversion
    if (case == "snake") {
        # Handle camelCase and PascalCase
        # Insert underscore before capital letters that follow lowercase letters
        new_names <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", new_names, perl = TRUE)
        
        # Convert to lowercase
        new_names <- tolower(new_names)
    }
    
    # Clean up underscores
    # Replace multiple consecutive underscores with a single one
    new_names <- gsub("_{2,}", "_", new_names)
    
    # Remove leading underscores
    new_names <- gsub("^_+", "", new_names)
    
    # Remove trailing underscores
    new_names <- gsub("_+$", "", new_names)
    
    # Handle empty names
    empty_names <- which(new_names == "" | is.na(new_names))
    if (length(empty_names) > 0) {
        new_names[empty_names] <- paste0("x", empty_names)
    }
    
    # Ensure names don't start with numbers
    starts_with_number <- grepl("^[0-9]", new_names)
    new_names[starts_with_number] <- paste0("x", new_names[starts_with_number])
    
    # Make names unique if requested
    if (use_make_names) {
        # Make syntactically valid names
        new_names <- make.names(new_names, unique = FALSE)
        
        # Replace dots with underscores (make.names uses dots)
        new_names <- gsub("\\.", "_", new_names)
        
        # Clean up multiple underscores again
        new_names <- gsub("_{2,}", "_", new_names)
        new_names <- gsub("_+$", "", new_names)
        
        # Handle duplicates
        if (any(duplicated(new_names))) {
            new_names <- make.unique(new_names, sep = "_")
        }
    }
    
    # Apply the new names
    names(dat) <- new_names
    return(dat)
}

#Apply corrections to input data
.apply_corrections <- function(data, file_type, verbose = FALSE) {
    
    
    corrections <- read_csv(here::here("db_files", "extractions_mislabelling_sheet.csv"),
                            show_col_types = FALSE) %>%
        .clean_names() %>% 
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
            
            # # Find matching rows
            # matching_rows <- rep(FALSE, nrow(data))
            # 
            # if (!is.na(correction$original_extraction_id) && 
            #     !is.na(correction$original_individual_id) &&
            #     !is.na(correction$original_extraction_plate_id) &&
            #     !is.na(correction$original_extraction_plate_well_address)) {
            #     
            #     matching_rows <- (data$extraction_id == correction$original_extraction_id) & 
            #         (data$individual_id == correction$original_individual_id) &
            #         (data$plateid == correction$original_extraction_plate_id) &
            #         (str_c(data$elution1_plate_column, data$elution1_plate_row) == correction$original_extraction_plate_well_address)
            #     matching_rows[is.na(matching_rows)] <- FALSE
            #     
            # } else if (!is.na(correction$original_extraction_id)) {
            #     matching_rows <- data$extraction_id == correction$original_extraction_id
            #     matching_rows[is.na(matching_rows)] <- FALSE
            # } else if (!is.na(correction$original_individual_id)) {
            #     matching_rows <- data$individual_id == correction$original_individual_id
            #     matching_rows[is.na(matching_rows)] <- FALSE
            # }
            
            # Build list of conditions
            conditions <- list()
            
            if (!is.na(correction$original_extraction_id)) {
                conditions$extraction <- data$extraction_id == correction$original_extraction_id
            }
            
            if (!is.na(correction$original_individual_id)) {
                conditions$individual <- data$individual_id == correction$original_individual_id
            }
            
            if (!is.na(correction$original_extraction_plate_id)) {
                conditions$plate <- data$plateid == correction$original_extraction_plate_id
            }
            
            if (!is.na(correction$original_extraction_plate_well_address)) {
                conditions$well <- str_c(data$elution1_plate_column, data$elution1_plate_row) == 
                    correction$original_extraction_plate_well_address
            }
            
            # Combine all conditions with AND logic
            if (length(conditions) > 0) {
                matching_rows <- reduce(conditions, `&`)
                matching_rows[is.na(matching_rows)] <- FALSE
            } else {
                # No conditions specified
                matching_rows <- rep(FALSE, nrow(data))
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
    
    raw_files <- list.files(here::here("db_files"), 
                            pattern = 'tsv$',
                            full.names = TRUE, 
                            recursive = TRUE) %>%
        str_subset('deprecated', negate = TRUE) %>%
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
        rowwise 
    
    raw_files %>%
        mutate(sheet = .apply_corrections(sheet, file_type, verbose) %>%
                   list()) %>%
        ungroup %>%
        mutate(sheet = set_names(sheet, file_type)) %>%
        pull(sheet)
}

.format_id_string <- function(x) {
    # Define the correct pattern with optional -Ex[0-9]+ suffix (one or more digits)
    correct_pattern <- "^[A-Z][a-z]{2}-[A-Z]{2}[a-z]{2}_[0-9]{3}(-Ex[0-9]+)?$"
    
    # Helper function to process a single string
    process_single <- function(s) {
        # Return NA if input is NA
        if (is.na(s)) return(NA_character_)
        
        # Convert to character if not already
        s <- as.character(s)
        
        # Check if already in correct format
        if (str_detect(s, correct_pattern)) {
            return(s)
        }
        
        # Clean the string - remove spaces
        s_clean <- str_remove_all(s, "\\s")
        
        # Initialize variables
        ex_suffix <- ""
        
        # Check if there's an Ex pattern and extract it
        if (str_detect(s_clean, "(?i)ex[0-9]+")) {
            # Find all matches of Ex followed by digits
            ex_matches <- str_extract_all(s_clean, "(?i)ex[0-9]+")[[1]]
            if (length(ex_matches) > 0) {
                # Take the last Ex pattern found
                last_ex <- ex_matches[length(ex_matches)]
                # Extract all the digits
                all_digits <- str_remove(last_ex, "(?i)ex")
                ex_suffix <- str_c("-Ex", all_digits)
                
                # Remove the Ex part from the string for processing the main part
                s_clean <- str_remove(s_clean, str_c("[-_]?", last_ex, "$"))
            }
        }
        
        # Now extract the main components (without Ex part)
        extracted <- str_match(s_clean, "([A-Za-z]{3})[-_]?([A-Za-z]{4})[-_]?([0-9]{1,3})")
        
        if (!is.na(extracted[1])) {
            part1 <- extracted[2]  # First 3 letters
            part2 <- extracted[3]  # Next 4 letters  
            part3 <- extracted[4]  # Numbers
            
            # Format part1: Upper + 2 lower
            part1_formatted <- str_c(
                str_to_upper(str_sub(part1, 1, 1)),
                str_to_lower(str_sub(part1, 2, 3))
            )
            
            # Format part2: 2 Upper + 2 lower
            part2_formatted <- str_c(
                str_to_upper(str_sub(part2, 1, 2)),
                str_to_lower(str_sub(part2, 3, 4))
            )
            
            # Format part3: Pad with zeros to make 3 digits
            part3_formatted <- str_pad(part3, width = 3, pad = "0")
            
            # Combine with correct separators
            result <- str_c(part1_formatted, "-", part2_formatted, "_", part3_formatted, ex_suffix)
            
            # Validate the result
            if (str_detect(result, correct_pattern)) {
                return(result)
            }
        }
        
        # If we couldn't fix it, return NA with a warning
        warning(str_glue("Could not format string: {s}"))
        return(NA_character_)
    }
    
    # Use map_chr from purrr to vectorize
    map_chr(x, process_single)
}

#### Assemble Database ####
.database_assembly <- function(){
    
    db_list <- .compile_db_inputs()
    
    ## Build Junction box to join in gel images
    db_list$dna_extractions_gels <- db_list$dna_extractions_gels %>%
        mutate(elution_plate_id = str_remove(gel_id, 
                                     '_20[0-9]{2}-[0-9]{2}-[0-9]{2}$') %>%
                   str_replace('elution-0', 'e'))
    
    
    db_list$elution_junction <- db_list$dna_extractions_sheets %>% 
        select(extraction_id, 
               elution1_plateid, 
               elution2_plateid, 
               elution3_plateid, 
               elution4_plateid) %>%
        pivot_longer(cols = ends_with("_plateid"),
                     names_to = "elution",
                     values_to = "elution_plate_id",
                     values_drop_na = TRUE) %>%
        mutate(elution = str_remove(elution, '_plateid')) %>%
        filter(elution_plate_id %in% unique(db_list$dna_extractions_gels$elution_plate_id))
    
    ## Construct database
    db_with_pk <- db_list %>% #names()
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
        dm::dm_add_pk(sequence_filename_sheets,
                      columns = c(file_prefix, hpc_path, hpc_name,
                                  extraction_id)) %>%
        dm::dm_add_pk(tissues_sheets,
                      columns = c(tissue_id)) %>%
        dm::dm_add_pk(xray_sheets,
                      columns = c(xray_file_base_name, 
                                  specimen_position)) %>%
        identity()
    
    db_with_pk %>%
        # dm_add_fk(table = lots_sheets,
        #           columns = lot_id,
        #           ref_table = sampling_sites_sheets,
        #           ref_columns = lot_id) %>%
        # dm_add_fk(table = sampling_sites_sheets,
        #           columns = lot_id,
        #           ref_table = lots_sheets,
        #           ref_columns = lot_id) %>%
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
        # dm_add_fk(table = dna_extractions_sheets, 
        #           columns = individual_id, 
        #           ref_table = individuals_sheets) %>%
        dm_add_fk(elution_junction,
                  elution_plate_id,
                  dna_extractions_gels, 
                  elution_plate_id) %>% 
        dm_add_fk(elution_junction, 
                  extraction_id, 
                  dna_extractions_sheets) %>%
        dm_add_fk(sequence_filename_sheets, 
                  extraction_id, 
                  dna_extractions_sheets) %>%
        dm_add_fk(tissues_sheets,
                  individual_id,
                  individuals_sheets) %>%
        dm_add_fk(dna_extractions_sheets,
                  tissue_id,
                  tissues_sheets) %>%
        dm_add_fk(xray_sheets,
                  individual_id,
                  individuals_sheets) %>%
        
        #Failed attempt ot join sequence info in based solely on metadata
        # dm_add_fk(table = sequence_info_sheets,
        #           columns = species_code,
        #           ref_table = species_sheets,
        #           ref_columns = species_code) %>%
        # dm_add_fk(table = sequence_info_sheets,
        #           columns = c(era, collection_year_start),
        #           ref_table = lots_sheets,
        #           ref_columns = c(collection_era, collection_year_start)) %>%
        # dm_add_fk(table = sequence_info_sheets,
        #           columns = c(site_id),
        #           ref_table = sampling_sites_sheets,
        #           ref_columns = c(site_id)) %>%
        identity()
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
pire_database <- function() {
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
.integrate_validated_files <- function(validation_results, apply_corrections = TRUE){
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
            processed_data <- .apply_corrections(result$data, table_type, verbose = FALSE)
        } else {
            processed_data <- result$data
        }
        
        #JDS HERE - Apply warning corrections for the database version
        # Create a separate copy for database integration with warning corrections applied
        db_data <- processed_data
        
        # Apply column structure warnings (remove extra columns)
        if (!is.null(result$warnings$columns)) {
            if (!is.null(result$warnings$columns$issues$extra)) {
                extra_cols <- result$warnings$columns$issues$extra
                cli_progress_step(paste("Removing extra columns:", paste(extra_cols, collapse = ", ")))
                db_data <- db_data %>%
                    select(-all_of(extra_cols))
            }
        }
        
        # Apply data quality warnings (trim whitespace, etc.)
        if (!is.null(result$warnings$quality)) {
            # Handle whitespace issues
            for (issue_name in names(result$warnings$quality$issues)) {
                if (str_detect(issue_name, "_whitespace$")) {
                    col_name <- str_remove(issue_name, "_whitespace$")
                    if (col_name %in% names(db_data)) {
                        cli_progress_step(paste("Trimming whitespace in column:", col_name))
                        db_data[[col_name]] <- str_trim(db_data[[col_name]])
                    }
                }
            }
            
            # Remove completely empty rows if they exist
            if (!is.null(result$warnings$quality$issues$empty_rows)) {
                empty_row_indices <- result$warnings$quality$issues$empty_rows
                cli_progress_step(paste("Removing", length(empty_row_indices), "empty rows"))
                # Create row numbers to match the original data
                db_data <- db_data %>%
                    mutate(.row_num = row_number()) %>%
                    filter(!.row_num %in% empty_row_indices) %>%
                    select(-.row_num)
            }
        }
        
        # Get existing table structure to ensure column order matches
        db <- pire_database()
        if (table_type %in% names(dm_get_tables(db))) {
            existing_table <- db %>% 
                dm_get_tables() %>%
                pluck(table_type)
            
            # Get expected columns (excluding the file path and correction tracking columns)
            expected_cols <- names(existing_table)
            correction_cols <- c("correction_applied", "correction_id", 
                                 "correction_details", "correction_date")
            filepath_cols <- paste0(table_type, 'file_path')
            expected_cols <- setdiff(expected_cols, c(correction_cols, filepath_cols))
            
            # Ensure db_data has exactly the expected columns in the right order
            # Add any missing columns as NA
            missing_cols <- setdiff(expected_cols, names(db_data))
            for (col in missing_cols) {
                db_data[[col]] <- NA
            }
            
            # Select only the expected columns in the correct order
            cols_to_keep <- intersect(expected_cols, names(db_data))
            db_data <- db_data %>%
                select(all_of(cols_to_keep))
            
            # Add correction tracking columns back if they exist in processed_data
            if (apply_corrections) {
                for (col in correction_cols) {
                    if (col %in% names(processed_data)) {
                        db_data[[col]] <- processed_data[[col]]
                    }
                }
            }
        }
        
        # Determine destination path
        dest_folder <- here::here("db_files", table_type)
        
        # Generate new filename with timestamp
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        original_name <- tools::file_path_sans_ext(basename(file_path))
        new_filename <- paste0(original_name, "_", timestamp, ".tsv")
        dest_path <- file.path(dest_folder, new_filename)
        
        # Write the cleaned data to database destination
        write_tsv(db_data, dest_path, na = "")
        
        # Archive the staging file with original processed_data (no warning corrections)
        archive_folder <- file.path(dirname(file_path), "processed")
        if (!dir.exists(archive_folder)) {
            dir.create(archive_folder)
        }
        
        archive_path <- file.path(archive_folder, paste0(original_name, "_processed_", timestamp, ".tsv"))
        # Write the original processed data to archive (with corrections but no warning fixes)
        write_tsv(processed_data, archive_path, na = "")
        
        # Remove the original staging file
        file.remove(file_path)
        
        cli_alert_success(paste("Integrated:", table_type, "-", basename(new_filename)))
        if (length(result$warnings) > 0) {
            cli_alert_info(paste("Applied", length(result$warnings), "warning correction(s) to database version"))
        }
    }
    
    cli_alert_success("All files integrated successfully")
    
    return(TRUE)
}

.format_extraction_id <- function(x) {
    # match pieces: 3 letters – 4 letters – digits – Ex + 1 digit
    m <- str_match(x, "^([A-Za-z]{3})-([A-Za-z]{4})_([0-9]+)-E[xX]([0-9])$")
    out <- rep(NA_character_, length(x))
    ok <- !is.na(m[, 1])
    
    if (any(ok)) {
        seg1 <- m[ok, 2]                         # 3 letters
        seg2 <- m[ok, 3]                         # 4 letters
        num  <- m[ok, 4]                         # digits
        exd  <- m[ok, 5]                         # 1 digit after Ex
        
        seg1_fmt <- paste0(toupper(substr(seg1, 1, 1)),
                           tolower(substr(seg1, 2, 3)))
        seg2_fmt <- paste0(toupper(substr(seg2, 1, 2)),
                           tolower(substr(seg2, 3, 4)))
        num_fmt  <- sprintf("%03d", as.integer(num)) # zero-pad to 3
        
        out[ok] <- paste0(seg1_fmt, "-", seg2_fmt, "_", num_fmt, "-Ex", exd)
    }
    
    out
}

.convert_decode <- function(decode_data){
    decode_data %>%
        rename(gcl_sequence_id = sequence_name,
               pire_sequence_id = extraction_id) %>%
        mutate(across(where(is.character), ~str_remove(., ' '))) %>%
        mutate(extraction_id = str_extract(pire_sequence_id, 
                                           "^.*[0-9]{3}([- _]E(x*)?[\\d\\?])?")) %>% 
        #fix commong errors
        mutate(extraction_id = str_replace_all(extraction_id, 
                                               c('_Ex' = '-Ex')),
               extraction_id = .format_extraction_id(extraction_id)) 
}


.match_column_types <- function(x, template, verbose = TRUE) {
    common <- intersect(names(x), names(template))
    
    safe_cast <- function(col, tmpl, nm) {
        # Special case: character -> numeric/integer
        if (is.character(col) && is.numeric(tmpl)) {
            out <- suppressWarnings(as.numeric(col))
            return(out)
        }
        if (is.character(col) && is.integer(tmpl)) {
            out <- suppressWarnings(as.integer(col))
            return(out)
        }
        
        # General case
        tryCatch(
            vec_cast(col, tmpl),
            vctrs_error_incompatible_type = function(e) {
                if (verbose) {
                    message(sprintf(
                        "Column `%s`: cannot cast <%s> to <%s>; leaving unchanged.",
                        nm, vec_ptype_full(col), vec_ptype_full(tmpl)
                    ))
                }
                col  # return original unchanged column
            }
        )
    }
    
    x %>%
        mutate(
            across(
                all_of(common),
                ~ safe_cast(.x, template[[cur_column()]], cur_column())
            )
        )
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
    db <- pire_database()
    
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
            enc <- stringi::stri_enc_detect(readr::read_file_raw(file))[[1]]
            best <- enc$Encoding[which.max(enc$Confidence)]
            
            data <- read_delim(file,
                               delim = '\t',
                               locale = readr::locale(encoding = best),
                               show_col_types = FALSE,
                               na = c("", "NA", "None"),
                               guess_max = 1e6) %>%
                rename_with(~str_to_lower(.x)) %>%
                mutate(across(everything(), ~str_trim(.x))) %>%
                .match_column_types(pull_tbl(db, !!sym(table_type)), verbose = FALSE)
            
            #
            
            
            #Covert decode format to accepted format
            if (table_type == 'sequence_filename_sheets' & ncol(data) == 2){
                data <- .convert_decode(data)
            }
            
            #Ensure extraction ID is formatted properly
            if (table_type == 'dna_extractions_sheets'){
                data <- mutate(data, extraction_id = .format_extraction_id(extraction_id))
            }
            
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
    .print_validation_summary_report(all_results, auto_integrate)
    
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
.print_validation_summary_report <- function(results, auto_integrate) {
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
    
    if (passed > 0 && failed == 0 && !auto_integrate) {
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


update_database <- function(integrate_files = FALSE){
    .validate_staging_files(auto_integrate = integrate_files)
}

#### GEOME Utilities ####
.message_tibble <- function(x) {
    stopifnot(inherits(x, "tbl_df"))
    msg <- paste(capture.output(print(x)), collapse = "\n")
    message(msg)
    invisible(x)
}


.make_geome_metadata <- function(extraction_ids, geome_ids = NULL){
    #extraction is required and is a character vector of the extraction IDs used.
    #geome_ids is optional. If included it is the values to be assigned to 
    #the materialSampleID (same order as extraction_ids). If not included
    #then these ids are generated by removing "-" and "_" from the individual id
    
    if (!is.null(geome_ids)) {
        if (!is.character(geome_ids) || length(geome_ids) != length(extraction_ids)) {
            stop("`geome_ids` must be a character vector with length = length(extraction_ids).")
        }
    }
    
    filtered_db <- pire_database() %>%
        dm_filter(dna_extractions_sheets = (extraction_id %in% extraction_ids)) %>%
        
        dm_select(lots_sheets, lot_id,
                  yearCollected = collection_year_start,
                  monthCollected = collection_month_start,
                  dayCollected = collection_day_start, 
                  identifiedBy = species_verified, 
                  preservative = storage_solution,
                  collection_era,
                  collection_site,
                  identificationRemarks1 = notes) %>%
        
        dm_select(sampling_sites_sheets, 
                  lot_id,
                  locality = local_government_unit, 
                  province,
                  decimalLatitude = latitude, 
                  decimalLongitude = longitude) %>%
        
        dm_select(species_sheets, 
                  species_valid_name, 
                  species_code) %>%
        
        dm_select(individuals_sheets, 
                  species_valid_name, 
                  individual_id, 
                  voucherCatalogNumber = new_usnm, 
                  lot_id,
                  yearIdentified = species_id_year,
                  identificationRemarks2 = species_id_notes) %>%
        
        dm_select(dna_extractions_sheets, 
                  individual_id, 
                  extraction_id,
                  date_subsampling,
                  tissueRecordedBy = subsampler,
                  tissueRemarks = notes) 
    
    out <- pull_tbl(filtered_db, 'dna_extractions_sheets') %>%
        full_join(pull_tbl(filtered_db, 'individuals_sheets'),
                  by = 'individual_id') %>%
        full_join(pull_tbl(filtered_db, 'lots_sheets'),
                  by = 'lot_id') %>%
        full_join(pull_tbl(filtered_db, 'sampling_sites_sheets'),
                  by = 'lot_id') %>%
        full_join(pull_tbl(filtered_db, 'species_sheets'),
                  by = 'species_valid_name') %>% #count(collection_era) #colnames()
        separate(species_valid_name, 
                 into = c('genus', 'specificEpithet'),
                 sep = '_', remove = FALSE) %>% #select(individual_id)
        
        mutate(principalInvestigator = 'Kent_Carpenter',
               across(c(locality, province),
                      ~str_replace_all(., ' ', '')), 
               across(c(locality, province),
                      ~str_replace_na(., replacement = 'NA')), 
               locality = str_c(locality, province, sep = '_'),
               country = 'Philippines',
               lifeStage = 'adult',
               across(c(identificationRemarks1, identificationRemarks2),
                      ~str_replace_na(., replacement = '')),
               identificationRemarks = str_c(identificationRemarks1, identificationRemarks2, sep = '; '),
               georeferenceProtocol = 'GoogleMaps',
               permitInformation = case_when(str_detect(province, 'Palawan') & collection_era == 'Contemporary' ~ 
                                                 "Palawan Council for Sustainable Development GP# 2022-4(R1)",
                                             TRUE ~ NA_character_),
               tissueType = 'muscle',
               preservative = case_when(preservative == 'EtOH' ~ "75% ethanol",
                                        TRUE ~ preservative),
               previousIdentifications = NA_character_,
               tissueInstitution = 'USNM',
               tissueSamplingYear = lubridate::year(date_subsampling),
               occurrenceRemarks = NA_character_, 
               voucherCatalogNumber = case_when(collection_era == 'Contemporary' ~ as.character(lot_id),
                                                collection_era == 'Albatross' ~ as.character(voucherCatalogNumber)),
               yearIdentified = case_when(!is.na(yearIdentified) ~ yearIdentified,
                                          TRUE ~ lubridate::year(date_subsampling)),
               samplingProtocol = case_when(collection_era == 'Contemporary' ~ 'marketcollection',
                                            collection_era == 'Albatross' ~ NA_character_),
               fieldNotes = NA_character_,
               tissuePreservative = '95% ethanol') %>% 
        
        {if (is.null(geome_ids)) {
            mutate(., materialSampleID = str_remove_all(extraction_id, '_|-'),
                   tissueID = materialSampleID)
        } else {
            mutate(., materialSampleID = geome_ids,
                   tissueID = materialSampleID)
        }} %>%
        
        select(species_code,
               collection_site,
               collection_era,
               
               materialSampleID,
               principalInvestigator,
               yearCollected,
               decimalLatitude,
               decimalLongitude,
               locality, country,
               genus, specificEpithet,
               lifeStage, 
               monthCollected, dayCollected,
               georeferenceProtocol, 
               permitInformation,
               tissueType,
               preservative,
               catalogNumber = extraction_id,
               occurrenceRemarks, #user needs to fill this from the field collection notes
               voucherCatalogNumber,
               identificationRemarks,
               identifiedBy, #user needs to modify this to fit with GEOME format
               previousIdentifications,
               scientificName = species_valid_name,
               yearIdentified,
               samplingProtocol, #user needs to fill in from https://www.google.com/maps/d/edit?mid=1leLurkYXC3FezrY59AhoU0QTjvi4fsIl&usp=sharing
               fieldNotes, #user needs to fill in from https://www.google.com/maps/d/edit?mid=1leLurkYXC3FezrY59AhoU0QTjvi4fsIl&usp=sharing & Field_Collections
               tissueID,
               tissueInstitution,
               tissueSamplingYear,
               tissueRecordedBy,
               tissuePreservative,
               tissueRemarks)
    
    
    field_notes_locations <- distinct(out,
                                      collection_era,
                                      field_note_location = collection_site,
                                      locality)
    
    message('User needs to fill "occurrenceRemarks" from the field collection notes (file path: ODUOneDrive/Field Collections)\n')
    message('User needs to modify "identifiedBy" to fit GEOME format: ')
    message("    List names with an underscore between the first and last name. If there is more than one name, use a space and the pipe operator '|' between each name (the pipe operator is specified to be used in the GEOME FAQs). Example: Kent_Carpenter | Maddy_Kenton.\n")
    message('User needs to fill "samplingProtocol" for albatross samples from https://www.google.com/maps/d/edit?mid=1leLurkYXC3FezrY59AhoU0QTjvi4fsIl&usp=sharing')
    message('    It should contain the notes with the sampling methods. Examples include “dynamite” and “beachseine”.\n')
    message('User needs to fill "fieldNotes')
    message('    For Albatross, copy from the site notes here https://www.google.com/maps/d/edit?mid=1leLurkYXC3FezrY59AhoU0QTjvi4fsIl&usp=sharing')
    message('    For Contemporary, copy or summarize from the field notes (file path: ODUOneDrive/Field Collections)\n')
    .message_tibble(field_notes_locations)
    message('\nUser needs to modify "tissueRecordedBy" to fit GEOME format: ')
    message("   List names with an underscore between the first and last name. If there is more than one name, use a space and the pipe operator '|' between each name (the pipe operator is specified to be used in the GEOME FAQs). Example: Kent_Carpenter | Maddy_Kenton.\n")
    
    message("   Other resources to find missing information:")
    #message("      * https://drive.google.com/file/d/1CLNuOJJAoEva_7wqxqVX3mDaNFH0cr-r/view")
    message("      * ODUOneDrive/ALBATROSS_1907-1910updatedALLrecordsNotations.xlsx\n")
    
    
    select(out, -collection_site, -collection_era)
}

.message_and_log <- function(..., file = NULL) {
    # Combine all arguments into a single string
    text <- paste0(..., collapse = "")
    
    message(text)  # Display on console
    if(!is.null(file)) {
        cat(text, "\n", file = file, append = TRUE, sep = "")  # Write to file only if path provided
    }
}


output_geome_metadata <- function(extraction_ids, sequence_ids = NULL, seq_type = NULL, output_path = NULL){
    if(!is.null(output_path)){
        dir.create(output_path, showWarnings = FALSE, recursive = TRUE)
        # output_file <- file.path(output_path, "upload_guidance.txt")
        # sink(output_file, split = TRUE)
        
        output_file <- file.path(output_path, "upload_guidance.txt")
    } else {
        output_file <- NULL
    }
    
    # Get data and prep names
    captured_output <- capture.output({
        output <- .make_geome_metadata(extraction_ids) %>%
            inner_join(tibble(catalogNumber = extraction_ids,
                              original_sequence_id = sequence_ids),
                       .,
                       by = 'catalogNumber') %>%
            relocate(catalogNumber, .after = 'preservative') %>%
            mutate(materialSampleID = str_c(materialSampleID, '_lib', 1:n()),
                   tissueID = materialSampleID,
                   .by = materialSampleID)
    }, type = "message") 
    
    # Display captured output to screen
    if(length(captured_output) > 0) {
        message(str_c(captured_output, collapse = '\n'))
        
        # Also write to file if output_path is not NULL
        if(!is.null(output_path)) {
            cat(captured_output, sep = "\n", file = output_file, append = TRUE)
            cat("\n", file = output_file, append = TRUE)  # Add extra newline
        }
    }
    
    
    expeditions <- distinct(output, species_code, yearCollected, locality) %>%
        mutate(expedition_name = str_c(species_code, yearCollected, locality, seq_type, sep = '_')) %>%
        right_join(output,
                   ., 
                   by = c('species_code', 'yearCollected', 'locality')) %>%
        select(-species_code) %>%
        nest(data = -c(expedition_name))
    
    #Output metadata
    if(!is.null(output_path)){
        .message_and_log('\nSaving GEOME Metadata files to: ', output_path, file = output_file)
        .message_and_log('  Saving Samples CSV files to: ', str_c(output_path, sep = '/'), file = output_file)
        with(expeditions,
             walk2(expedition_name,
                   data,
                   ~{
                       file <- file.path(output_path, paste0(.x, ".csv"))
                       readr::write_csv(select(.y, -original_sequence_id), file)
                       .message_and_log("    Saved file: ", file, file = output_file)
                   }))
    }

    
    #Output fasta renaming script
    if(!is.null(sequence_ids)){
        .message_and_log('  \nFASTQ Library Metadata:', file = output_file)
        .message_and_log('    Library Layout: Paired-End', file = output_file)
        if(all(str_detect(seq_type, 'CSSL|cssl'))){
            .message_and_log('    Library Strategy: OTHER', file = output_file)
        } else {
            .message_and_log('    Library Strategy: WGS', file = output_file)
        }
        .message_and_log('    Library Source: GENOMIC', file = output_file)
        # Library Selection
        if(all(str_detect(seq_type, 'CSSL|cssl'))){
            .message_and_log('    Library Selection: "Reduced Representation"', file = output_file)
        } else if(all(str_detect(seq_type, 'wgs'))){
            .message_and_log('    Library Selection: "Other"', file = output_file)
        } else if(all(str_detect(seq_type, 'SSL|ssl'))){
            .message_and_log('    Library Selection: "size fractionation"', file = output_file)
        }
        .message_and_log('    Platform: ILLUMINA', file = output_file)
        .message_and_log('    Instrument Model: Illumina NovaSeq 6000', file = output_file)
        .message_and_log('    Protocol Citation or Website: KAPA HyperPlus Kit', file = output_file)
        
        fastq_info <- unnest(expeditions, data) %>%
            select(expedition_name, materialSampleID, catalogNumber,
                   original_sequence_id) %>%
            mutate(sequence_id = str_replace(basename(original_sequence_id),
                                             catalogNumber, 
                                             materialSampleID))
        
        if(!is.null(output_path)){
            .message_and_log('\n  Saving FASTQ renaming script to: ', 
                    str_c(output_path, 'rename_seqs_for_ncbi.slurm', sep = '/'), file = output_file)
            .message_and_log('    Copy this script to the "./fq_raw" directory and run to create ', file = output_file)
            .message_and_log('    softlinks with the proper names in "./fq_raw/ncbi_upload"', file = output_file)
            sequence_rename <- select(fastq_info,
                                      expedition_name,
                                      original_sequence_id, sequence_id) %>%
                expand_grid(direction = c('1', '2')) %>%
                mutate(original_sequence_id = str_c(original_sequence_id, direction, 'fq.gz', sep = '.'),
                       sequence_id = str_c(sequence_id, direction, 'fq.gz', sep = '.') %>%
                           str_c('./ncbi_upload/', expedition_name, '/', .),
                       .keep = 'unused') 
            
            
            dirs <- unique(dirname(sequence_rename$sequence_id))
            
            
            # make a list of rsync commands
            cmds <- apply(sequence_rename, 1, function(r) {
                src <- r[["original_sequence_id"]]
                dst <- r[["sequence_id"]]
                sprintf('rsync -a --partial --inplace --info=progress2 "%s" "%s"', src, dst)
            })
            
            # assemble the script
            script <- c(
                "#!/usr/bin/env bash",
                "#SBATCH --job-name=copyForNCBI",
                "#SBATCH -o copyForNCBI-%j.out",
                "#SBATCH -p main",
                "#SBATCH --cpus-per-task=20", 
                "set -euo pipefail",
                "",
                "",
                "#raw_file_dir=${1}",
                "#raw_file_dir=./1st_sequencing_run/fq_raw",
                "#cd ${raw_file_dir}",
                "",
                "# 1) make all destination folders first",
                sprintf("mkdir -p %s", shQuote(dirs)),
                "",
                "# 2) run rsync in parallel (adjust -j for # of jobs)",
                "parallel -j ${SLURM_CPUS_ON_NODE} ::: \\",
                paste(sprintf("  '%s'", cmds), collapse=" \\\n")
            )
            
            write_lines(script, str_c(output_path, 'rename_seqs_for_ncbi.slurm', sep = '/'))
            Sys.chmod(str_c(output_path, 'rename_seqs_for_ncbi.slurm', sep = '/'), mode = "0755")
        }
    
        
        if(!is.null(output_path)){
            .message_and_log('\n  Saving FASTQ Data CSV files to: ', str_c(output_path, sep = '/'), file = output_file)
            fastq_csv_files <- fastq_info %>%
                select(expedition_name, sequence_id) %>%
                expand_grid(direction = c('1', '2')) %>%
                mutate(sequence_id = str_c(sequence_id, direction, 'fq.gz', sep = '.'),
                       .keep = 'unused') %>%
                nest(data = -c(expedition_name))
            
            with(fastq_csv_files,
                 walk2(expedition_name,
                       data,
                       ~{
                           file <- file.path(output_path, paste0(.x, ".txt"))
                           readr::write_tsv(.y, file, col_names = FALSE)
                           .message_and_log("    Saved file: ", file, file = output_file)
                       }))
        }
 
        
        
    }
    
    ncbi_text_out <- select(expeditions, expedition_name) %>%
        separate(expedition_name, 
                 into = c('species_code', 'year',
                          'local', 'region', 'study_type'),
                 sep = '_',
                 remove = FALSE) %>%
        nest(location_info = -c(species_code)) %>%
        inner_join(pire_database() %>% 
                       pull_tbl('species_sheets') %>%
                       select(species_code, species_valid_name),
                   by = 'species_code') %>%
        unnest(location_info) %>%
        mutate(ncbi_title = str_c("Project Title:",
                                  str_replace(expedition_name,
                                        species_code,
                                        species_valid_name)),
               ncbi_description = str_c("Project Description:",
                                        str_replace_all(study_type, 
                                                        c('lcwgs' = 'Low coverage whole genome',
                                                          'cssl' = 'Capture',
                                                          'ssl' = 'Shotgun')),
                                        'sequencing data for the fish',
                                        str_replace_all(species_valid_name, 
                                                    '_', ' '),
                                        'collected in',
                                        year, 'in',
                                        str_c(local, 
                                              region, 
                                              'Philippines.',
                                              sep = ', '),
                                        sep = ' '),
               .keep = 'none')
    
    for(i in 1:nrow(ncbi_text_out)){
        .message_and_log('\n', file = output_file)
        .message_and_log(ncbi_text_out$ncbi_title[i], file = output_file)
        .message_and_log(ncbi_text_out$ncbi_description[i], file = output_file)
    }
    
    .message_and_log("\n", file = output_file)
    .message_and_log("Relevance: Evolution", file = output_file)
    .message_and_log("  External links:", file = output_file)
    .message_and_log("    - Description: Philippines PIRE Project: Centennial Genetic and Species Transformations in the Epicenter of Marine Biodiversity URL: https://sites.wp.odu.edu/PIRE/philippines/", file = output_file)
    .message_and_log("    - Description: Philippines PIRE Project Metadata URL: https://geome-db.org/workbench/project-overview?projectId=511", file = output_file)
    
    .message_and_log("\n", file = output_file)
    .message_and_log("Grant ID: OISE-1743711", file = output_file)
    .message_and_log("Grant Title: Centennial Genetic and Species Transformations in the Epicenter of Marine Biodiversity", file = output_file)
    .message_and_log("Agency: National Science Foundation", file = output_file)
    .message_and_log("Agency Abbreviation: NSF", file = output_file)
    
    .message_and_log('-----------------------------------------------\n', file = output_file)
    arrange(expeditions, expedition_name)
}
