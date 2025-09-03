# .Rprofile - Project setup with system dependency checking

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
  
  # Check if on Linux and check system dependencies
  if (Sys.info()["sysname"] == "Linux") {
    cat("\n🐧 Linux system detected - checking system dependencies...\n")
    
    # Function to check if a system library is installed
    check_system_lib <- function(lib_name) {
      result <- suppressWarnings(system2("ldconfig", 
                                        args = c("-p"), 
                                        stdout = TRUE, 
                                        stderr = FALSE))
      any(grepl(lib_name, result))
    }
    
    # List of common system dependencies for R packages
    system_deps <- list(
      "libglpk" = "libglpk-dev",        # for igraph
      "libcurl" = "libcurl4-openssl-dev", # for curl, httr
      "libssl" = "libssl-dev",          # for openssl
      "libxml2" = "libxml2-dev",        # for xml2
      "libgit2" = "libgit2-dev",        # for gert
      "libfontconfig" = "libfontconfig1-dev", # for systemfonts
      "libfreetype" = "libfreetype6-dev",     # for ragg
      "libharfbuzz" = "libharfbuzz-dev",      # for textshaping
      "libfribidi" = "libfribidi-dev",        # for textshaping
      "libtiff" = "libtiff5-dev",       # for tiff images
      "libjpeg" = "libjpeg-dev",        # for jpeg
      "libpng" = "libpng-dev",          # for png
      "libpq" = "libpq-dev",            # for RPostgreSQL
      "libmysqlclient" = "libmysqlclient-dev", # for RMySQL
      "libsqlite3" = "libsqlite3-dev"   # for RSQLite
    )
    
    missing_libs <- c()
    for (lib in names(system_deps)) {
      if (!check_system_lib(lib)) {
        missing_libs <- c(missing_libs, system_deps[[lib]])
      }
    }
    
    if (length(missing_libs) > 0) {
      cat("   ⚠️  Some system libraries may be missing\n")
      cat("\n   If package installation fails, you may need to install:\n")
      cat("   sudo apt-get update\n")
      cat("   sudo apt-get install", paste(missing_libs, collapse = " "), "\n")
    } else {
      cat("   ✓ Common system libraries detected\n")
    }
  }
  
  # Check package management status
  cat("\n📦 Checking R environment...\n")
  
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
          cat("   ⚠️  Missing", length(missing), "out of", length(required), "R packages\n")
          if (length(missing) <= 5) {
            cat("   Need:", paste(missing, collapse = ", "), "\n")
          } else {
            cat("   Examples:", paste(head(missing, 3), collapse = ", "), "...\n")
          }
        }
        return(FALSE)
      } else {
        if (!silent) cat("   ✅ All", length(required), "R packages installed\n")
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
  
  # Define helper functions
  install_linux_deps <- function() {
    if (Sys.info()["sysname"] != "Linux") {
      cat("This function is only for Linux systems.\n")
      return(invisible(NULL))
    }
    
    cat("\n🐧 LINUX SYSTEM DEPENDENCIES\n")
    cat("===============================\n")
    cat("\nThis project's R packages may require system libraries.\n")
    cat("\nRun these commands in your terminal (not in R):\n\n")
    
    # Comprehensive list for common R packages
    cat("# Update package list\n")
    cat("sudo apt-get update\n\n")
    
    cat("# Install essential compilation tools\n")
    cat("sudo apt-get install -y build-essential gfortran\n\n")
    
    cat("# Install common R package dependencies\n")
    cat("sudo apt-get install -y \\\n")
    cat("  libcurl4-openssl-dev \\\n")
    cat("  libssl-dev \\\n")
    cat("  libxml2-dev \\\n")
    cat("  libfontconfig1-dev \\\n")
    cat("  libharfbuzz-dev \\\n")
    cat("  libfribidi-dev \\\n")
    cat("  libfreetype6-dev \\\n")
    cat("  libpng-dev \\\n")
    cat("  libtiff5-dev \\\n")
    cat("  libjpeg-dev \\\n")
    cat("  libglpk-dev \\\n")        # Critical for igraph
    cat("  libgit2-dev \\\n")
    cat("  libsqlite3-dev \\\n")
    cat("  libpq-dev \\\n")
    cat("  libssh2-1-dev \\\n")
    cat("  unixodbc-dev \\\n")
    cat("  libcairo2-dev \\\n")
    cat("  libxt-dev \\\n")
    cat("  libgdal-dev \\\n")        # for spatial packages
    cat("  libudunits2-dev \\\n")    # for units package
    cat("  libgeos-dev \\\n")        # for spatial packages
    cat("  libproj-dev\n")           # for spatial packages
    
    cat("\n# For igraph specifically (your current issue):\n")
    cat("sudo apt-get install -y libglpk-dev\n")
    
    cat("\n===============================\n")
    cat("After installing system libraries, return to R and run:\n")
    cat("  setup_project()\n\n")
  }
  
  setup_project <- function() {
    cat("\n🔧 Setting up project environment...\n\n")
    
    # Check for Linux dependencies first
    if (Sys.info()["sysname"] == "Linux") {
      cat("📝 NOTE: On Linux, some R packages need system libraries.\n")
      cat("   If installation fails, run: install_linux_deps()\n")
      cat("   for instructions on installing system dependencies.\n\n")
    }
    
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
    cat("Step 2: Installing R packages (this may take 5-10 minutes)...\n\n")
    
    # Try to restore, catching errors for missing system deps
    tryCatch({
      renv::restore(prompt = FALSE)
      cat("\n✅ Setup complete!\n")
      cat("   Please restart R (Session → Restart R or Ctrl+Shift+F10)\n")
      cat("   Then run: open_main_script()\n")
    }, error = function(e) {
      if (grepl("(libglpk|compilation failed|undefined symbol)", e$message, ignore.case = TRUE)) {
        cat("\n❌ Package installation failed - likely missing system libraries\n")
        cat("\n", e$message, "\n")
        cat("\nRun: install_linux_deps()\n")
        cat("for commands to install required system libraries,\n")
        cat("then try setup_project() again.\n")
      } else {
        cat("\n❌ Installation error:\n")
        cat(e$message, "\n")
      }
    })
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
    }
  }
  
  check_setup <- function() {
    cat("\n📋 DETAILED STATUS CHECK\n")
    cat("========================\n")
    
    # System info
    cat("\n💻 System:\n")
    cat("   OS:", Sys.info()["sysname"], Sys.info()["release"], "\n")
    cat("   R version:", R.version.string, "\n")
    
    # Working directory
    cat("\n📁 Working directory:\n   ", getwd(), "\n")
    
    # Check Linux dependencies if on Linux
    if (Sys.info()["sysname"] == "Linux") {
      cat("\n🐧 Linux system libraries:\n")
      cat("   Run install_linux_deps() for system dependency info\n")
    }
    
    # renv status
    cat("\n📦 Package management (renv):\n")
    if (!requireNamespace("renv", quietly = TRUE)) {
      cat("   ❌ renv not installed\n")
    } else {
      renv_ver <- as.character(packageVersion("renv"))
      cat("   ✓ renv version:", renv_ver, "\n")
      
      if (file.exists("renv.lock")) {
        cat("   ✓ renv.lock found\n")
        .check_dependencies(silent = FALSE)
      } else {
        cat("   ❌ renv.lock not found\n")
      }
    }
    
    # Project files
    cat("\n📄 Project files:\n")
    files <- c(
      "scripts/assemble_db.R",
      "renv.lock",
      ".Rprofile",
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
  }
  
  # Make functions globally available
  assign("setup_project", setup_project, envir = .GlobalEnv)
  assign("open_main_script", open_main_script, envir = .GlobalEnv)  
  assign("check_setup", check_setup, envir = .GlobalEnv)
  assign("install_linux_deps", install_linux_deps, envir = .GlobalEnv)
  
  # Display instructions based on status
  cat("\n------------------------------------------------------------\n")
  
  if (!renv_available) {
    cat(" 🔧 INITIAL SETUP REQUIRED\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run: setup_project()\n\n")
    if (Sys.info()["sysname"] == "Linux") {
      cat(" Linux users: You may also need system libraries.\n")
      cat(" Run: install_linux_deps() for instructions\n\n")
    }
  } else if (!deps_ok && lockfile_exists) {
    cat(" 📦 PACKAGE INSTALLATION NEEDED\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run: setup_project()\n\n")
    if (Sys.info()["sysname"] == "Linux") {
      cat(" If installation fails with compilation errors:\n")
      cat(" Run: install_linux_deps() for system requirements\n\n")
    }
  } else if (deps_ok) {
    cat(" ✅ PROJECT READY\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run: open_main_script()\n\n")
  }
  
  cat(" Available commands:\n")
  cat("   • setup_project()     - Install/update R packages\n")
  cat("   • open_main_script()  - Open main script\n")
  cat("   • check_setup()       - Show detailed status\n")
  if (Sys.info()["sysname"] == "Linux") {
    cat("   • install_linux_deps() - Show Linux system requirements\n")
  }
  cat("\n============================================================\n\n")
}