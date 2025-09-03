# .Rprofile - Project setup with clean output

# Suppress renv activation messages
local({
  # Capture and suppress renv's output
  suppressMessages({
    suppressWarnings({
      tryCatch({
        # Temporarily suppress all output
        invisible(capture.output({
          source("renv/activate.R")
        }))
      }, error = function(e) {
        # Silently handle any renv activation errors
        # renv will bootstrap itself if needed
      })
    })
  })
})

# Run our setup with clean output
local({
  
  # Only run in interactive sessions
  if (!interactive()) {
    return(invisible(NULL))
  }
  
  # Clear any residual renv messages and start fresh
  cat("\n============================================================\n")
  cat(" PROJECT: database_albatross_recollections\n")
  cat("============================================================\n")
  
  # Set working directory
  tryCatch({
    if (exists(".rs.getProjectDirectory")) {
      setwd(.rs.getProjectDirectory())
      cat("\n📁 Working directory set\n")
    } else if (file.exists("database_albatross_recollections.Rproj")) {
      cat("\n📁 Working directory confirmed\n")
    }
    cat("   ", getwd(), "\n")
  }, error = function(e) {
    cat("\n📁 Working directory: ", getwd(), "\n")
  })
  
  # Check renv status
  cat("\n📦 Checking package management...\n")
  
  # Check if renv is available (it should be after activation)
  if (!requireNamespace("renv", quietly = TRUE)) {
    cat("   ⚠️  renv needs to be installed\n")
    cat("\n To set up this project, run:\n")
    cat("   install.packages('renv')\n")
    cat("   Then restart R\n")
    return(invisible(NULL))
  }
  
  # Check if renv.lock exists
  if (!file.exists("renv.lock")) {
    cat("   ⚠️  renv.lock not found\n")
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
      
      # Suppress renv's status messages during our check
      suppressMessages({
        lockfile <- renv::lockfile_read("renv.lock")
      })
      
      required <- names(lockfile$Packages)
      installed <- rownames(installed.packages())
      missing <- setdiff(required, installed)
      
      if (length(missing) > 0) {
        if (!silent) {
          cat("   ⚠️  Missing", length(missing), "out of", length(required), "packages\n")
          if (length(missing) <= 5) {
            cat("   Need:", paste(missing, collapse = ", "), "\n")
          } else {
            cat("   Examples:", paste(head(missing, 3), collapse = ", "), "...\n")
          }
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
  
  # Run the dependency check
  deps_ok <- .check_dependencies(silent = FALSE)
  
  # Create helper functions
  setup_project <- function() {
    # Ensure renv is installed
    if (!requireNamespace("renv", quietly = TRUE)) {
      cat("\n📦 Installing renv first...\n")
      install.packages("renv")
    }
    
    cat("\n📦 Installing all project dependencies...\n")
    cat("   This may take 5-10 minutes on first run.\n")
    cat("   Package installation progress will appear below...\n\n")
    
    # Make sure we're in the right directory
    if (file.exists("renv.lock")) {
      # Don't suppress renv::restore() output - users want to see progress
      renv::restore(prompt = FALSE)
      cat("\n✅ Installation complete!\n")
      cat("   Please restart R (Session → Restart R or Ctrl+Shift+F10)\n")
    } else {
      cat("\n❌ Error: renv.lock not found in current directory\n")
      cat("   Current directory:", getwd(), "\n")
    }
  }
  
  open_main_script <- function() {
    # Check dependencies first
    if (!.check_dependencies(silent = TRUE)) {
      cat("\n⚠️  Some packages are not installed yet!\n")
      cat("   Run setup_project() first, then restart R.\n")
      return(invisible(NULL))
    }
    
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
      cat("   ✓ renv is installed\n")
      
      # Get renv version quietly
      renv_ver <- tryCatch({
        as.character(packageVersion("renv"))
      }, error = function(e) "unknown")
      cat("   Version:", renv_ver, "\n")
      
      if (file.exists("renv.lock")) {
        cat("   ✓ renv.lock found\n")
        .check_dependencies(silent = FALSE)
      } else {
        cat("   ⚠️  renv.lock NOT found\n")
      }
    } else {
      cat("   ⚠️  renv NOT installed\n")
      cat("   Run: install.packages('renv')\n")
    }
    
    # Package library (concise)
    cat("\n📚 Package library:\n")
    lib_path <- .libPaths()[1]
    if (grepl("renv", lib_path)) {
      cat("   ✓ Using renv library\n")
    } else {
      cat("   Using system library\n")
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
    if (!.check_dependencies(silent = TRUE)) {
      cat("➡️  Next step: Run setup_project()\n")
    } else {
      cat("➡️  Ready! Run open_main_script()\n")
    }
  }
  
  # Make functions available globally
  assign("setup_project", setup_project, envir = .GlobalEnv)
  assign("open_main_script", open_main_script, envir = .GlobalEnv)  
  assign("check_setup", check_setup, envir = .GlobalEnv)
  
  # Show clear instructions based on status
  cat("\n------------------------------------------------------------\n")
  if (!deps_ok) {
    cat(" 🚀 FIRST TIME SETUP REQUIRED\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run these commands:\n\n")
    cat("   setup_project()    # Install all packages (5-10 min)\n")
    cat("   # Then restart R (Session → Restart R)\n")
    cat("   open_main_script() # Open the main script\n")
  } else {
    cat(" ✅ PROJECT READY\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run:  open_main_script()\n\n")
    cat(" This opens: scripts/assemble_db.R\n")
  }
  
  cat("\n Other commands:\n")
  cat("   check_setup() - Show detailed status\n")
  cat("\n============================================================\n\n")
})

# Fallback in case something goes wrong above
if (interactive() && !exists("check_setup")) {
  check_setup <- function() {
    cat("\nBasic diagnostic:\n")
    cat("• Working directory:", getwd(), "\n")
    cat("• Files present:", paste(list.files(pattern = "\\.(R|Rproj)$"), collapse = ", "), "\n")
    cat("\nTry running: source('.Rprofile')\n")
  }
  assign("check_setup", check_setup, envir = .GlobalEnv)
}