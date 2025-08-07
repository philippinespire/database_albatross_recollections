source("renv/activate.R")

# ---- Open all *.R and *.qmd files in analysis/construction on project load -----
if (interactive() &&
    requireNamespace("later",      quietly = TRUE) &&
    requireNamespace("rstudioapi", quietly = TRUE)) {

  later::later(function() {

    ## Collect files ------------------------------------------------------------
    project_root <- tryCatch(rstudioapi::getActiveProject(),
                             error = function(e) NULL)
    if (is.null(project_root)) project_root <- getwd()

    #files_to_open <- list.files(
    #  file.path(project_root, "scripts"),
    #  pattern = "\\.(R)$",
    #  full.names = TRUE,
    #  ignore.case = TRUE
    #)
    files_to_open <- c('scripts/assemble_db.R')
    files_to_open <- sort(normalizePath(files_to_open, winslash = "/"))

    if (!length(files_to_open)) {
      message("[startup-helper] No .R or .qmd files found.")
      return(invisible())
    }

    ## Helper -------------------------------------------------------------------
    safe_open <- function(path) {
      ext <- tools::file_ext(path)

      # For .qmd files, avoid RStudio's YAML dependency parser if yaml isn't installed
      if (tolower(ext) == "qmd" && !requireNamespace("yaml", quietly = TRUE)) {
        try(file.edit(path), silent = TRUE)
        return(TRUE)
      }

      opened <- FALSE
      if (rstudioapi::isAvailable() && rstudioapi::hasFun("openFile")) {
        opened <- tryCatch({
          rstudioapi::callFun("openFile", path)
          TRUE
        }, error = function(e) FALSE)
      }
      if (!opened) try(file.edit(path), silent = TRUE)
      TRUE                               # <- always return a logical(1)
    }

    ## Open every file ----------------------------------------------------------
    for (f in files_to_open) safe_open(f)

  }, delay = 2)      # seconds; increase if your IDE needs more time to settle
}