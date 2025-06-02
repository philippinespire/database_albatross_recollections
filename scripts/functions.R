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
