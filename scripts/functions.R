#### install_and_load_functions ####

#' Install and load a set of CRAN, Bioconductor, and GitHub packages
#'
#' @param cran_packages    Character vector of CRAN package names.
#' @param special_packages A list of named lists, each describing a
#'        non-CRAN package with elements
#'        \code{pkg}, \code{source} (\"Bioc\" | \"GitHub\"),
#'        \code{repo}  (for GitHub), and optional \code{install_options}.
#' @param set_repos        Logical.  If TRUE, calls \code{setRepositories(ind = repos_ind)}.
#' @param repos_ind        Integer vector passed to \code{setRepositories()} when
#'        \code{set_repos = TRUE}.
#'
#' @examples
#' install_and_load()                      # use defaults below
#' install_and_load(cran_packages = "fs")  # custom CRAN vector
install_and_load_packages <- function(
    cran_packages = c(
      "tidyverse",
      "janitor",
      "readxl"
    ),
    special_packages = list(
      ## example template — uncomment / add as needed
      # list(pkg = "Biostrings", source = "Bioc",   repo = "Biostrings"),
      # list(pkg = "ggimage",    source = "GitHub", repo = "GuangchuangYu/ggimage")
    ),
    set_repos  = TRUE,
    repos_ind  = 1:2
) {
  
  if (set_repos) {
    setRepositories(ind = repos_ind)
  }
  
  ## ------------------------------------------------------------------
  ## Helper: install (if needed) and load a single package -------------
  ## ------------------------------------------------------------------
  load_install_pkg <- function(pkg, source = "CRAN",
                               repo = NULL,
                               install_options = list()) {
    
    if (!suppressPackageStartupMessages(
      require(pkg, character.only = TRUE))) {
      
      message("Package '", pkg,
              "' not found. Attempting installation from ", source, " …")
      
      tryCatch({
        
        if (source == "CRAN") {
          
          install.packages(pkg,
                           Ncpus = max(1L, parallel::detectCores() - 1))
          
        } else if (source == "Bioc") {
          
          if (!requireNamespace("BiocManager", quietly = TRUE))
            install.packages("BiocManager")
          do.call(BiocManager::install,
                  c(list(pkg), install_options))
          
        } else if (source == "GitHub") {
          
          if (is.null(repo))
            stop("For GitHub installation, 'repo' must be supplied (", pkg, ").",
                 call. = FALSE)
          
          if (!requireNamespace("devtools", quietly = TRUE))
            install.packages("devtools")
          do.call(devtools::install_github,
                  c(list(repo), install_options))
          
        } else {
          
          stop("Unknown source '", source, "' for package '", pkg, "'.",
               call. = FALSE)
        }
        
      }, error = function(e) {
        message("Installation of '", pkg, "' failed: ", e$message)
      })
      
      ## Try loading again -------------------------------------------------
      if (!suppressPackageStartupMessages(
        require(pkg, character.only = TRUE))) {
        message("⚠️  Still failed to load '", pkg, "'.")
      } else {
        message("✅ Successfully loaded '", pkg, "'.")
      }
      
    } else {
      message("✔︎ Package '", pkg, "' already loaded.")
    }
  }
  
  ## ------------------------------------------------------------------
  ## Process CRAN packages --------------------------------------------
  ## ------------------------------------------------------------------
  for (pkg in cran_packages) {
    load_install_pkg(pkg, source = "CRAN")
  }
  
  ## ------------------------------------------------------------------
  ## Process special (Bioc / GitHub) packages -------------------------
  ## ------------------------------------------------------------------
  for (pkg_info in special_packages) {
    load_install_pkg(
      pkg             = pkg_info$pkg,
      source          = pkg_info$source,
      repo            = pkg_info$repo,
      install_options = pkg_info$install_options %||% list()
    )
  }
  
  invisible(TRUE)
}

# small infix helper (safe default) used above
`%||%` <- function(a, b) if (is.null(a)) b else a

#### Compile Database Files ####
#### Function to Apply Corrections ####
#Apply corrections to input data
apply_corrections <- function(data, file_type, verbose = FALSE) {
    corrections <- read_excel("./db_files/extractions_mislabelling_sheet.xlsx") %>%
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

# Compile database for use
compile_db_inputs <- function(verbose = FALSE){

        list.files("./db_files", 
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
        summarise(sheet = bind_rows(sheet) %>%
                      list(),
                  .by = file_type) %>%
        rowwise %>%
        mutate(sheet = apply_corrections(sheet, file_type, verbose) %>%
                   distinct() %>%
                   rename_with(~str_to_lower(.x)) %>%
                   mutate(across(matches("filter_out_this_row"), ~replace_na(., FALSE))) %>%
                   filter(if_any(matches("filter_out_this_row"), ~!.)) %>%
                   select(-matches('filter_out_this_row')) %>%
                   list()) %>%
        ungroup %>%
        mutate(sheet = set_names(sheet, file_type)) %>%
        pull(sheet)
}



#### Identify Rows in Tables missing the primary key ####
find_missing_pks <- function(db, sheet, pk_col){
    #db - database: full_db
    #sheet - character: dna_extractions_sheets
    #pk_col - character: primary key column(s) seperated by comma in single string
    #can get sheet and pk_col from dm_get_all_pks(db)
    
    all_pk_cols <- str_split(pk_col, ',') %>%
        unlist %>%
        str_trim()
    
    pull_tbl(db, !!sym(sheet)) %>%
        filter(if_any(all_of(all_pk_cols), is.na))
}
