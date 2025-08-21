source("renv/activate.R")

# .Rprofile - Project setup and dependency checking

if (interactive()) {
  
  # Set working directory to project root
  if (exists(".rs.getProjectDirectory")) {
    setwd(.rs.getProjectDirectory())
  } else if (file.exists("database_albatross_recollections.Rproj")) {
    setwd(getwd())
  }
  
  # Simple startup message
  cat("\n============================================================\n")
  cat(" PROJECT: database_albatross_recollections\n")
  cat("============================================================\n")
  
  # Check if packages need to be installed
  .check_dependencies <- function(silent = FALSE) {
    if (!file.exists("renv.lock")) {
      if (!silent) cat("\n⚠️  No renv.lock file found\n")
      return(invisible(FALSE))
    }
    
    lockfile <- renv::lockfile_read("renv.lock")
    required <- names(lockfile$Packages)
    installed <- rownames(installed.packages())
    missing <- setdiff(required, installed)
    
    if (length(missing) > 0) {
      if (!silent) {
        cat("\n⚠️  PACKAGES NEED TO BE INSTALLED\n")
        cat("   Missing", length(missing), "packages\n\n")
      }
      return(invisible(FALSE))
    } else {
      if (!silent) cat("\n✅ All packages installed\n")
      return(invisible(TRUE))
    }
  }
  
  # Check dependencies on startup
  deps_ok <- .check_dependencies(silent = FALSE)
  
  if (!deps_ok) {
    cat("============================================================\n")
    cat(" ACTION REQUIRED:\n")
    cat("============================================================\n")
    cat("\n Run this command to install all required packages:\n\n")
    cat("   renv::restore()\n\n")
    cat(" This will take a few minutes on first setup.\n")
    cat(" After installation, restart R (Session → Restart R)\n")
    cat("============================================================\n\n")
  }
  
  # Create helper functions
  setup_project <- function() {
    cat("\n📦 Installing all project dependencies...\n")
    cat("   This may take several minutes on first run.\n\n")
    renv::restore(prompt = FALSE)
    cat("\n✅ Installation complete!\n")
    cat("   Please restart R (Session → Restart R or Ctrl+Shift+F10)\n")
    cat("   Then run: open_main_script()\n")
  }
  
  open_main_script <- function() {
    # First check if packages are installed
    if (!.check_dependencies(silent = TRUE)) {
      cat("\n⚠️  Packages not installed yet!\n")
      cat("   Please run: setup_project()\n")
      cat("   Then restart R and try again.\n")
      return(invisible(NULL))
    }
    
    script_path <- "scripts/assemble_db.R"
    if (file.exists(script_path)) {
      cat("Opening:", script_path, "\n")
      file.edit(script_path)
    } else {
      stop("File not found: ", script_path)
    }
  }
  
  check_setup <- function() {
    cat("\n📋 SETUP CHECK\n")
    cat("====================\n")
    
    # Working directory
    cat("\n📁 Working directory:\n   ", getwd(), "\n")
    
    # renv library
    cat("\n📚 Package library:\n   ", .libPaths()[1], "\n")
    
    # Check packages
    cat("\n📦 Package status:\n")
    .check_dependencies(silent = FALSE)
    
    # Check files
    cat("\n📄 Project files:\n")
    files <- c("scripts/assemble_db.R", "renv.lock", ".Rprofile")
    for (f in files) {
      if (file.exists(f)) {
        cat("   ✓", f, "\n")
      } else {
        cat("   ✗", f, "NOT FOUND\n")
      }
    }
    
    cat("\n====================\n")
    if (!.check_dependencies(silent = TRUE)) {
      cat("\n➡️  Next step: Run setup_project()\n")
    } else {
      cat("\n➡️  Ready! Run open_main_script()\n")
    }
  }
  
  # Make functions available globally
  assign("setup_project", setup_project, envir = .GlobalEnv)
  assign("open_main_script", open_main_script, envir = .GlobalEnv)
  assign("check_setup", check_setup, envir = .GlobalEnv)
  
  # Final instructions based on status
  if (deps_ok) {
    cat("\n🎉 Project ready! Commands available:\n")
    cat("   • open_main_script() - Open the main script\n")
    cat("   • check_setup()      - Check project status\n\n")
  } else {
    cat("📌 Commands available:\n")
    cat("   • setup_project()    - Install all packages (run this first!)\n")
    cat("   • check_setup()      - Check project status\n")
    cat("   • open_main_script() - Open main script (after setup)\n\n")
  }
}