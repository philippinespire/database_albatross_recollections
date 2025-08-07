source("renv/activate.R")

# .Rprofile - Ensures proper environment setup and package installation

if (interactive()) {
  
  # Set working directory to project root
  if (exists(".rs.getProjectDirectory")) {
    project_dir <- .rs.getProjectDirectory()
    setwd(project_dir)
  } else if (file.exists("database_albatross_recollections.Rproj")) {
    project_dir <- getwd()
  }
  
  # Display startup message
  cat("\n", rep("=", 60), sep = "")
  cat("\n PROJECT: database_albatross_recollections")
  cat("\n", rep("=", 60), sep = "")
  
  # Verify working directory
  cat("\n\n📁 Working directory:")
  cat("\n   ", getwd())
  
  # Verify renv is active
  cat("\n\n📦 Package library (renv):")
  cat("\n   ", .libPaths()[1])
  
  # Check if renv packages are installed
  cat("\n\n📋 Checking package dependencies...")
  
  # Check if renv.lock exists
  if (file.exists("renv.lock")) {
    
    # Parse the renv.lock file to check packages
    lockfile <- renv::lockfile_read("renv.lock")
    required_packages <- names(lockfile$Packages)
    
    # Get currently installed packages
    installed_packages <- rownames(installed.packages())
    
    # Find missing packages
    missing_packages <- setdiff(required_packages, installed_packages)
    
    if (length(missing_packages) > 0) {
      cat("\n\n", rep("⚠", 3), " MISSING PACKAGES DETECTED ", rep("⚠", 3), sep = "")
      cat("\n\n   Missing", length(missing_packages), "out of", length(required_packages), "required packages")
      cat("\n   Examples:", paste(head(missing_packages, 5), collapse = ", "))
      if (length(missing_packages) > 5) {
        cat("\n   ... and", length(missing_packages) - 5, "more")
      }
      
      cat("\n\n", rep("🔧", 30), sep = "")
      cat("\n TO INSTALL ALL REQUIRED PACKAGES, RUN:")
      cat("\n", rep("🔧", 30), sep = "")
      cat("\n\n   renv::restore()")
      cat("\n\n This will install all packages with the exact versions")
      cat("\n specified in renv.lock, ensuring reproducibility.")
      cat("\n", rep("=", 60), sep = "")
      
      # Offer to install automatically
      cat("\n\n Would you like to install missing packages now?")
      cat("\n Type 'yes' to run renv::restore() or 'no' to skip: ")
      
      # Set up a one-time prompt
      if (!exists(".renv_restore_prompted")) {
        .renv_restore_prompted <<- TRUE
        
        # Use a callback to handle the response after user can type
        addTaskCallback(function(...) {
          response <- readline("")
          if (tolower(trimws(response)) %in% c("yes", "y")) {
            cat("\n Installing packages... This may take a few minutes.\n")
            cat(" (Subsequent users won't need to do this)\n\n")
            renv::restore(prompt = FALSE)
            cat("\n✅ Package installation complete!")
            cat("\n   Please restart R to ensure all packages are loaded correctly.")
            cat("\n   (Session → Restart R or Ctrl+Shift+F10)\n")
          } else {
            cat("\n Skipping package installation.")
            cat("\n Remember to run renv::restore() before running project scripts.\n")
          }
          return(FALSE)  # Remove this callback
        })
      }
      
    } else {
      cat("\n   ✅ All", length(required_packages), "required packages are installed")
      
      # Optionally show key packages
      key_packages <- c("tidyverse", "data.table", "ggplot2", "dplyr", "readr")
      key_installed <- intersect(key_packages, required_packages)
      if (length(key_installed) > 0) {
        cat("\n\n📚 Key packages available:")
        for (pkg in key_installed) {
          pkg_version <- packageVersion(pkg)
          cat("\n   •", pkg, paste0("(v", pkg_version, ")"))
        }
      }
    }
    
  } else {
    cat("\n\n ⚠️  WARNING: renv.lock file not found!")
    cat("\n    The project's package dependencies are not specified.")
    cat("\n    You may need to:")
    cat("\n    1. Run renv::init() to initialize renv, or")
    cat("\n    2. Get the renv.lock file from the repository")
  }
  
  # Check critical files
  cat("\n\n✓ Project structure:")
  critical_files <- c(
    "scripts/assemble_db.R",
    "renv.lock",
    ".Rprofile"
  )
  
  for (file in critical_files) {
    if (file.exists(file)) {
      cat("\n   ✓", file)
    } else {
      cat("\n   ✗", file, "NOT FOUND")
    }
  }
  
  # Instructions
  cat("\n\n", rep("-", 60), sep = "")
  cat("\n 🚀 TO GET STARTED:")
  cat("\n", rep("-", 60), sep = "")
  cat("\n\n 1. Ensure packages are installed: renv::restore()")
  cat("\n 2. Open the main script: file.edit('scripts/assemble_db.R')")
  cat("\n 3. All paths in scripts are relative to:", basename(getwd()))
  cat("\n", rep("=", 60), sep = "")
  
  # Helper function
  open_main_script <- function() {
    if (file.exists("scripts/assemble_db.R")) {
      file.edit("scripts/assemble_db.R")
    } else {
      stop("scripts/assemble_db.R not found.")
    }
  }
  assign("open_main_script", open_main_script, envir = .GlobalEnv)
  
  cat("\n\n💡 Type open_main_script() to open the main script\n\n")
}