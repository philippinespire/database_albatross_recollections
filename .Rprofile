# .Rprofile - Project setup with error handling

# Safely try to activate renv
tryCatch({
  source("renv/activate.R")
}, error = function(e) {
  cat("\n⚠️  renv activation issue (this is normal on first run)\n")
  cat("   The project will set up renv now.\n\n")
})

# Make sure the rest of the script runs even if renv has issues
local({
  
  # Debug: Confirm .Rprofile is running
  cat("\n[.Rprofile loading...]\n")
  
  # Only run in interactive sessions
  if (!interactive()) {
    cat("[Non-interactive session - skipping setup]\n")
    return(invisible(NULL))
  }
  
  cat("\n============================================================\n")
  cat(" PROJECT: database_albatross_recollections\n")
  cat("============================================================\n")
  
  # Set working directory
  tryCatch({
    if (exists(".rs.getProjectDirectory")) {
      setwd(.rs.getProjectDirectory())
      cat("📁 Working directory set via RStudio\n")
    } else if (file.exists("database_albatross_recollections.Rproj")) {
      # Already in correct directory
      cat("📁 Working directory confirmed\n")
    }
    cat("   ", getwd(), "\n")
  }, error = function(e) {
    cat("📁 Working directory: ", getwd(), "\n")
  })
  
  # Check renv status
  cat("\n📦 Checking package management...\n")
  
  # Check if renv is available
  if (!requireNamespace("renv", quietly = TRUE)) {
    cat("\n⚠️  renv is not installed\n")
    cat("\n To set up this project, run:\n")
    cat("   install.packages('renv')\n")
    cat("   renv::restore()\n")
    cat("   Then restart R\n")
    return(invisible(NULL))
  }
  
  # Check if renv is initialized
  if (!file.exists("renv.lock")) {
    cat("\n⚠️  renv.lock not found\n")
    cat("   Cannot check package dependencies\n")
    return(invisible(NULL))
  }
  
  # Safe dependency check
  .check_dependencies <- function(silent = FALSE) {
    tryCatch({
      if (!file.exists("renv.lock")) {
        if (!silent) cat("   No renv.lock file\n")
        return(FALSE)
      }
      
      # Check if renv functions are available
      if (!exists("lockfile_read", where = asNamespace("renv"), mode = "function")) {
        if (!silent) cat("   renv not fully loaded\n")
        return(FALSE)
      }
      
      lockfile <- renv::lockfile_read("renv.lock")
      required <- names(lockfile$Packages)
      installed <- rownames(installed.packages())
      missing <- setdiff(required, installed)
      
      if (length(missing) > 0) {
        if (!silent) {
          cat("   ⚠️  Missing", length(missing), "out of", length(required), "packages\n")
          cat("   Examples:", paste(head(missing, 3), collapse = ", "), "\n")
        }
        return(FALSE)
      } else {
        if (!silent) cat("   ✅ All", length(required), "packages installed\n")
        return(TRUE)
      }
    }, error = function(e) {
      if (!silent) cat("   Could not check dependencies\n")
      return(FALSE)
    })
  }
  
  # Run the check
  deps_ok <- .check_dependencies(silent = FALSE)
  
  # Create helper functions
  setup_project <- function() {
    # First ensure renv is installed
    if (!requireNamespace("renv", quietly = TRUE)) {
      cat("\n📦 Installing renv first...\n")
      install.packages("renv")
    }
    
    cat("\n📦 Installing all project dependencies...\n")
    cat("   This may take 5-10 minutes on first run.\n\n")
    
    # Make sure we're in the right directory
    if (file.exists("renv.lock")) {
      renv::restore(prompt = FALSE)
      cat("\n✅ Installation complete!\n")
      cat("   Please restart R (Session → Restart R)\n")
    } else {
      cat("\n❌ Error: renv.lock not found in current directory\n")
      cat("   Current directory:", getwd(), "\n")
    }
  }
  
  open_main_script <- function() {
    script_path <- "scripts/assemble_db.R"
    if (file.exists(script_path)) {
      cat("Opening:", script_path, "\n")
      if (requireNamespace("rstudioapi", quietly = TRUE) && 
          rstudioapi::isAvailable()) {
        rstudioapi::navigateToFile(script_path)
      } else {
        file.edit(script_path)
      }
    } else {
      cat("❌ File not found:", script_path, "\n")
      cat("   Current directory:", getwd(), "\n")
    }
  }
  
  check_setup <- function() {
    cat("\n📋 SETUP CHECK\n")
    cat("====================\n")
    
    # Working directory
    cat("\n📁 Working directory:\n   ", getwd(), "\n")
    
    # R version
    cat("\n📊 R version:\n   ", R.version.string, "\n")
    
    # renv status
    cat("\n📦 renv status:\n")
    if (requireNamespace("renv", quietly = TRUE)) {
      cat("   renv is installed\n")
      if (file.exists("renv.lock")) {
        cat("   renv.lock found\n")
        .check_dependencies(silent = FALSE)
      } else {
        cat("   ⚠️  renv.lock NOT found\n")
      }
    } else {
      cat("   ⚠️  renv NOT installed\n")
      cat("   Run: install.packages('renv')\n")
    }
    
    # Package library
    cat("\n📚 Package library paths:\n")
    for (lib in .libPaths()) {
      cat("   ", lib, "\n")
    }
    
    # Check files
    cat("\n📄 Project files:\n")
    files <- c("scripts/assemble_db.R", "renv.lock", ".Rprofile", "renv/activate.R")
    for (f in files) {
      if (file.exists(f)) {
        cat("   ✓", f, "\n")
      } else {
        cat("   ✗", f, "NOT FOUND\n")
      }
    }
    
    cat("\n====================\n")
    cat("➡️  If setup needed, run: setup_project()\n")
    cat("➡️  To open main script: open_main_script()\n")
  }
  
  # Make functions available globally
  assign("setup_project", setup_project, envir = .GlobalEnv)
  assign("open_main_script", open_main_script, envir = .GlobalEnv)  
  assign("check_setup", check_setup, envir = .GlobalEnv)
  
  # Show instructions
  cat("\n------------------------------------------------------------\n")
  if (!deps_ok) {
    cat(" FIRST TIME SETUP REQUIRED\n")
    cat("------------------------------------------------------------\n\n")
    cat(" 1. Run:  setup_project()\n")
    cat(" 2. Wait for packages to install (5-10 minutes)\n")
    cat(" 3. Restart R when complete\n")
    cat(" 4. Run:  open_main_script()\n")
  } else {
    cat(" PROJECT READY\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run:  open_main_script()  to begin\n")
  }
  
  cat("\n Other commands:\n")
  cat("   • check_setup() - Diagnose any issues\n")
  cat("\n============================================================\n\n")
})

# Make sure functions are available even if there were errors above
if (interactive() && !exists("check_setup")) {
  check_setup <- function() {
    cat("\nBasic diagnostic:\n")
    cat("• R version:", R.version.string, "\n")
    cat("• Working directory:", getwd(), "\n")
    cat("• .Rprofile location:", file.path(getwd(), ".Rprofile"), "\n")
    cat("• File exists:", file.exists(".Rprofile"), "\n")
    cat("\nIf you're not seeing startup messages, try:\n")
    cat("1. Make sure you're in the project directory\n")
    cat("2. Run: source('.Rprofile')\n")
    cat("3. Check for errors in renv/activate.R\n")
  }
  assign("check_setup", check_setup, envir = .GlobalEnv)
}