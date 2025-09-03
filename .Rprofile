# .Rprofile - Project setup with clean output

# Suppress renv activation messages but don't print NULL
if (file.exists("renv/activate.R")) {
  quietly <- function(expr) {
    sink(tempfile())
    on.exit(sink())
    suppressMessages(suppressWarnings(expr))
  }
  
  tryCatch({
    quietly(source("renv/activate.R"))
  }, error = function(e) {
    # Silent - renv will bootstrap if needed
  })
}

# Always run our setup regardless of renv status
if (interactive()) {
  
  # Clear line and start our output
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
  
  # Check package management status
  cat("\n📦 Checking environment...\n")
  
  # Determine renv status
  renv_available <- requireNamespace("renv", quietly = TRUE)
  lockfile_exists <- file.exists("renv.lock")
  
  if (!renv_available) {
    cat("   ⚠️  renv not installed (needed for package management)\n")
  } else if (!lockfile_exists) {
    cat("   ⚠️  renv.lock not found (needed for dependencies)\n")
  } else {
    cat("   ✓ renv active\n")
  }
  
  # Safe dependency check function
  .check_dependencies <- function(silent = FALSE) {
    if (!renv_available || !lockfile_exists) {
      if (!silent) cat("   Dependencies cannot be checked\n")
      return(FALSE)
    }
    
    tryCatch({
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
      if (!silent) cat("   Error checking dependencies\n")
      return(FALSE)
    })
  }
  
  # Check dependencies if possible
  deps_ok <- FALSE
  if (renv_available && lockfile_exists) {
    deps_ok <- .check_dependencies(silent = FALSE)
  }
  
  # Define helper functions (always create these)
  setup_project <- function() {
    cat("\n🔧 Setting up project environment...\n\n")
    
    # Install renv if needed
    if (!requireNamespace("renv", quietly = TRUE)) {
      cat("Step 1: Installing renv package manager...\n")
      install.packages("renv")
      cat("✓ renv installed\n\n")
    }
    
    # Check for lockfile
    if (!file.exists("renv.lock")) {
      cat("❌ Error: renv.lock not found in project directory\n")
      cat("   Current directory:", getwd(), "\n")
      cat("   Please ensure you're in the project root directory\n")
      return(invisible(NULL))
    }
    
    # Restore packages
    cat("Step 2: Installing project packages (this may take 5-10 minutes)...\n\n")
    renv::restore(prompt = FALSE)
    
    cat("\n✅ Setup complete!\n")
    cat("   Please restart R (Session → Restart R or Ctrl+Shift+F10)\n")
    cat("   Then run: open_main_script()\n")
  }
  
  open_main_script <- function() {
    # Quick dependency check if renv is available
    if (requireNamespace("renv", quietly = TRUE) && file.exists("renv.lock")) {
      if (!.check_dependencies(silent = TRUE)) {
        cat("\n⚠️  Some packages are missing!\n")
        cat("   Run setup_project() first, then restart R.\n")
        return(invisible(NULL))
      }
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
      cat("   Expected location:", file.path(getwd(), script_path), "\n")
    }
  }
  
  check_setup <- function() {
    cat("\n📋 DETAILED STATUS CHECK\n")
    cat("========================\n")
    
    # Working directory
    cat("\n📁 Working directory:\n   ", getwd(), "\n")
    
    # R version
    cat("\n📊 R version:\n   ", R.version.string, "\n")
    
    # renv status
    cat("\n📦 Package management (renv):\n")
    if (!requireNamespace("renv", quietly = TRUE)) {
      cat("   ❌ renv not installed\n")
      cat("   → Run: install.packages('renv')\n")
    } else {
      renv_ver <- as.character(packageVersion("renv"))
      cat("   ✓ renv version:", renv_ver, "\n")
      
      if (file.exists("renv.lock")) {
        cat("   ✓ renv.lock found\n")
        
        # Try to check dependencies
        tryCatch({
          suppressMessages({
            lockfile <- renv::lockfile_read("renv.lock")
            cat("   Total packages required:", length(lockfile$Packages), "\n")
          })
          .check_dependencies(silent = FALSE)
        }, error = function(e) {
          cat("   Could not read package requirements\n")
        })
      } else {
        cat("   ❌ renv.lock not found\n")
      }
    }
    
    # Library paths
    cat("\n📚 Library paths:\n")
    libs <- .libPaths()
    for (i in seq_along(libs)) {
      if (grepl("renv", libs[i])) {
        cat("   [", i, "] ✓ renv library:", libs[i], "\n")
      } else {
        cat("   [", i, "] System:", libs[i], "\n")
      }
    }
    
    # Project files
    cat("\n📄 Project files:\n")
    files <- c(
      "scripts/assemble_db.R",
      "renv.lock",
      ".Rprofile",
      "renv/activate.R",
      "database_albatross_recollections.Rproj"
    )
    for (f in files) {
      if (file.exists(f)) {
        cat("   ✓", f, "\n")
      } else {
        cat("   ✗", f, "- NOT FOUND\n")
      }
    }
    
    cat("\n========================\n")
    if (!requireNamespace("renv", quietly = TRUE) || !deps_ok) {
      cat("→ Next step: Run setup_project()\n")
    } else {
      cat("→ Ready! Run open_main_script()\n")
    }
  }
  
  # Make functions globally available
  assign("setup_project", setup_project, envir = .GlobalEnv)
  assign("open_main_script", open_main_script, envir = .GlobalEnv)  
  assign("check_setup", check_setup, envir = .GlobalEnv)
  
  # Display instructions based on status
  cat("\n------------------------------------------------------------\n")
  
  if (!renv_available) {
    cat(" 🔧 INITIAL SETUP REQUIRED\n")
    cat("------------------------------------------------------------\n\n")
    cat(" This project uses renv for package management.\n\n")
    cat(" Run: setup_project()\n\n")
    cat(" This will:\n")
    cat("   1. Install renv\n")
    cat("   2. Install all project packages\n")
    cat("   3. Set up your environment\n")
  } else if (!lockfile_exists) {
    cat(" ⚠️  PROJECT FILES INCOMPLETE\n")
    cat("------------------------------------------------------------\n\n")
    cat(" renv.lock file is missing.\n")
    cat(" Please ensure you have the complete project.\n")
  } else if (!deps_ok) {
    cat(" 📦 PACKAGE INSTALLATION NEEDED\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run: setup_project()\n\n")
    cat(" This will install all required packages (~5-10 minutes)\n")
    cat(" After completion, restart R and run: open_main_script()\n")
  } else {
    cat(" ✅ PROJECT READY\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run: open_main_script()\n\n")
    cat(" This opens the main script: scripts/assemble_db.R\n")
  }
  
  cat("\n Available commands:\n")
  cat("   • setup_project()    - Install/update packages\n")
  cat("   • open_main_script() - Open main script\n")
  cat("   • check_setup()      - Show detailed status\n")
  cat("\n============================================================\n\n")
}