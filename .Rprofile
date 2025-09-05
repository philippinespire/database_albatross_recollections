# .Rprofile - Project setup with system dependency checking

# Suppress renv activation messages more safely
renv_activated <- FALSE
if (file.exists("renv/activate.R")) {
  tryCatch({
    # Capture output without using sink (more reliable across platforms)
    invisible(utils::capture.output({
      suppressMessages(suppressWarnings({
        source("renv/activate.R")
        renv_activated <- TRUE
      }))
    }))
  }, error = function(e) {
    # Silent - renv will bootstrap if needed
    renv_activated <- FALSE
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
  
  # Check system-specific dependencies
  sys_name <- Sys.info()["sysname"]
  
  if (sys_name == "Windows") {
    cat("\n🪟 Windows system detected\n")
    
    # Check for Rtools on Windows
    check_rtools <- function() {
      # Check if make is available (indicates Rtools is installed)
      make_path <- Sys.which("make")
      if (make_path == "") {
        # Also check common Rtools locations
        rtools_paths <- c(
          "C:\\rtools43\\usr\\bin",
          "C:\\rtools42\\usr\\bin", 
          "C:\\rtools40\\usr\\bin",
          "C:\\Rtools\\bin"
        )
        for (path in rtools_paths) {
          if (dir.exists(path)) {
            return(TRUE)
          }
        }
        return(FALSE)
      }
      return(TRUE)
    }
    
    if (!check_rtools()) {
      cat("   ⚠️  Rtools not detected (needed for some package installations)\n")
      cat("   If package installation fails, install Rtools from:\n")
      cat("   https://cran.r-project.org/bin/windows/Rtools/\n")
    } else {
      cat("   ✔ Rtools detected\n")
    }
    
  } else if (sys_name == "Linux") {
    cat("\n🐧 Linux system detected\n")
    
    # Function to check if a system library is installed
    check_system_lib <- function(lib_name) {
      result <- suppressWarnings(system2("ldconfig", 
                                        args = c("-p"), 
                                        stdout = TRUE, 
                                        stderr = FALSE))
      any(grepl(lib_name, result))
    }
    
    # Check for essential build tools
    if (system2("which", args = "gcc", stdout = FALSE, stderr = FALSE) != 0) {
      cat("   ⚠️  GCC compiler not found - install build-essential\n")
    } else {
      cat("   ✔ Build tools detected\n")
    }
    
    # Check for critical libraries needed by YOUR packages
    libs_to_check <- list(
      "libcurl" = "needed for curl, httr, httr2",
      "libssl" = "needed for openssl (dependency of several packages)",
      "libxml2" = "needed for XML parsing (potential dependency)",
      "libgit2" = "needed for gert package"
    )
    
    for (lib in names(libs_to_check)) {
      if (!check_system_lib(lib)) {
        cat("   ⚠️ ", lib, " not found (", libs_to_check[[lib]], ")\n", sep="")
      }
    }
    
  } else if (sys_name == "Darwin") {
    cat("\n🍎 macOS system detected\n")
    # Check for Xcode command line tools
    if (system2("which", args = "clang", stdout = FALSE, stderr = FALSE) != 0) {
      cat("   ⚠️  Xcode Command Line Tools may not be installed\n")
      cat("   Install with: xcode-select --install\n")
    } else {
      cat("   ✔ Development tools detected\n")
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
    cat("   ✔ renv active\n")
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
  
  # Windows-specific function
  install_windows_tools <- function() {
    if (Sys.info()["sysname"] != "Windows") {
      cat("This function is only for Windows systems.\n")
      return(invisible(NULL))
    }
    
    cat("\n🪟 WINDOWS BUILD TOOLS (Rtools)\n")
    cat("=====================================\n")
    cat("\nSome R packages need compilation tools on Windows.\n")
    cat("\nTo fix 'make not found' and similar errors:\n\n")
    
    # Detect R version for correct Rtools version
    r_version <- paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
    
    cat("1. Download and install Rtools for your R version (", R.version.string, "):\n\n")
    
    if (r_version >= "4.5") {
      cat("   Download Rtools45 from:\n")
      cat("   https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html\n")
    } else if (r_version >= "4.4") {
      cat("   Download Rtools44 from:\n")
      cat("   https://cran.r-project.org/bin/windows/Rtools/rtools44/rtools.html\n")
    }else if (r_version >= "4.3") {
      cat("   Download Rtools43 from:\n")
      cat("   https://cran.r-project.org/bin/windows/Rtools/rtools43/rtools.html\n")
    } else if (r_version >= "4.2") {
      cat("   Download Rtools42 from:\n")
      cat("   https://cran.r-project.org/bin/windows/Rtools/rtools42/rtools.html\n")
    } else if (r_version >= "4.0") {
      cat("   Download Rtools40 from:\n")
      cat("   https://cran.r-project.org/bin/windows/Rtools/\n")
    }
    
    cat("\n2. Run the installer with default settings\n")
    cat("   (It will install to C:\\rtools43 or similar)\n")
    
    cat("\n3. Restart RStudio after installation\n")
    
    cat("\n4. Run setup_project() again\n")
    
    cat("\n=====================================\n")
    cat("\nAlternative: Force binary package installation\n")
    cat("(This avoids compilation but may get slightly older versions)\n\n")
    cat('options(pkgType = "binary")\n')
    cat("setup_project()\n")
    cat("\n=====================================\n")
  }
  
  # Linux-specific function
  install_linux_deps <- function() {
  if (Sys.info()["sysname"] != "Linux") {
    cat("This function is only for Linux systems.\n")
    return(invisible(NULL))
  }
  
  cat("\n🐧 LINUX SYSTEM DEPENDENCIES\n")
  cat("===============================\n")
  cat("\nThese system libraries are required by your R packages.\n\n")
  
  cat("STEP 1: Update your package list\n")
  cat("─────────────────────────────────\n")
  cat("Copy and paste this command:\n\n")
  cat("sudo apt-get update\n")
  
  cat("\n\nSTEP 2: Install compilation tools\n")
  cat("──────────────────────────────────\n")
  cat("Copy and paste this command:\n\n")
  cat("sudo apt-get install -y build-essential gfortran\n")
  
  cat("\n\nSTEP 3: Install required libraries\n")
  cat("───────────────────────────────────\n")
  cat("Copy and paste this entire block:\n\n")
  
  # Print the command without comments
  cat("sudo apt-get install -y \\
  libcurl4-openssl-dev \\
  libssl-dev \\
  libxml2-dev \\
  libgit2-dev \\
  libfontconfig1-dev \\
  libfreetype6-dev \\
  libpng-dev \\
  libjpeg-dev \\
  libtiff5-dev \\
  libharfbuzz-dev \\
  libfribidi-dev \\
  libglpk-dev \\
  libgmp3-dev \\
  libmpfr-dev \\
  libicu-dev \\
  libcairo2-dev \\
  libxt-dev \\
  cmake \\
  pandoc \\
  pandoc-citeproc\n")
  
  cat("\n\nWHAT THESE LIBRARIES ARE FOR:\n")
  cat("─────────────────────────────\n")
  cat("• libcurl4-openssl-dev : curl, httr, httr2, devtools\n")
  cat("• libssl-dev          : openssl, credentials, gargle, gert\n")
  cat("• libxml2-dev         : xml2, rvest, roxygen2, devtools\n")
  cat("• libgit2-dev         : gert\n")
  cat("• libfontconfig1-dev  : systemfonts, ragg, ggplot2\n")
  cat("• libfreetype6-dev    : systemfonts, ragg\n")
  cat("• libpng-dev          : ragg, PNG support\n")
  cat("• libjpeg-dev         : ragg, JPEG support\n")
  cat("• libtiff5-dev        : ragg, TIFF support\n")
  cat("• libharfbuzz-dev     : textshaping (required by ragg)\n")
  cat("• libfribidi-dev      : textshaping (bidirectional text)\n")
  cat("• libglpk-dev         : igraph (graph algorithms)\n")
  cat("• libgmp3-dev         : precision math operations\n")
  cat("• libmpfr-dev         : precision math operations\n")
  cat("• libicu-dev          : stringi (text processing)\n")
  cat("• libcairo2-dev       : graphics device\n")
  cat("• libxt-dev           : X11 toolkit\n")
  cat("• cmake               : build tool for some packages\n")
  cat("• pandoc              : rmarkdown, knitr\n")
  cat("• pandoc-citeproc     : citations in rmarkdown\n")
  
  cat("\n\nOPTIONAL: Database libraries (if needed)\n")
  cat("─────────────────────────────────────────\n")
  cat("Only install these if you plan to use database connections:\n\n")
  cat("# PostgreSQL support:\n")
  cat("sudo apt-get install -y libpq-dev\n\n")
  cat("# MySQL support:\n")
  cat("sudo apt-get install -y libmysqlclient-dev\n\n")
  cat("# SQLite support:\n")
  cat("sudo apt-get install -y libsqlite3-dev\n")
  
  cat("\n\nOPTIONAL: Additional libraries\n")
  cat("───────────────────────────────\n")
  cat("Only if you get specific errors:\n\n")
  cat("# V8 JavaScript engine:\n")
  cat("sudo apt-get install -y libv8-dev\n\n")
  cat("# SSH operations:\n")
  cat("sudo apt-get install -y libssh2-1-dev\n\n")
  cat("# Encryption:\n")
  cat("sudo apt-get install -y libsodium-dev\n")
  
  cat("\n===============================\n")
  cat("After installing, return to R and run: setup_project()\n\n")
  
  cat("TROUBLESHOOTING:\n")
  cat("───────────────\n")
  cat("If you still get compilation errors after installing these,\n")
  cat("the error message will usually indicate which library is missing.\n")
  cat("Search for: \"R package [package_name] system requirements ubuntu\"\n")
}
  
  setup_project <- function(binary_only = FALSE) {
    cat("\n🔧 Setting up project environment...\n\n")
    
    # Platform-specific warnings
    if (sys_name == "Windows") {
      if (binary_only) {
        cat("📦 Installing binary packages only (no compilation needed)...\n\n")
        options(pkgType = "binary")
      } else {
        # Check for Rtools
        make_available <- Sys.which("make") != ""
        if (!make_available) {
          cat("⚠️  WARNING: Rtools not detected!\n")
          cat("   If you see 'make not found' errors, either:\n")
          cat("   1. Run: install_windows_tools() and install Rtools, OR\n")
          cat("   2. Run: setup_project(binary_only = TRUE) to use pre-built packages\n\n")
        }
      }
    } else if (sys_name == "Linux") {
      cat("📋 NOTE: On Linux, some packages need system libraries.\n")
      cat("   If installation fails, run: install_linux_deps()\n\n")
    }
    
    # Install renv if needed
    if (!requireNamespace("renv", quietly = TRUE)) {
      cat("Step 1: Installing renv package manager...\n")
      install.packages("renv")
      cat("✔ renv installed\n\n")
    }
    
    # Check for lockfile
    if (!file.exists("renv.lock")) {
      cat("❌ Error: renv.lock not found in project directory\n")
      cat("   Current directory:", getwd(), "\n")
      return(invisible(NULL))
    }
    
    # Restore packages
    cat("Step 2: Installing R packages (this may take 5-10 minutes)...\n\n")
    
    # Try to restore, catching common errors
    tryCatch({
      renv::restore(prompt = FALSE)
      cat("\n✅ Setup complete!\n")
      cat("   Please restart R (Session → Restart R or Ctrl+Shift+F10)\n")
      cat("   Then run: open_main_script()\n")
    }, error = function(e) {
      error_msg <- tolower(e$message)
      
      if (grepl("make.*not found", error_msg)) {
        cat("\n❌ Compilation failed - 'make' not found\n\n")
        cat("This means Rtools is not installed. You have two options:\n\n")
        cat("OPTION 1: Install Rtools (recommended)\n")
        cat("   Run: install_windows_tools()\n")
        cat("   Follow the instructions, then run setup_project() again\n\n")
        cat("OPTION 2: Use pre-built binaries (easier but may be older versions)\n")
        cat("   Run: setup_project(binary_only = TRUE)\n\n")
      } else if (grepl("(libcurl|libssl|libgit2|libxml2|compilation failed|undefined symbol)", error_msg)) {
        cat("\n❌ Compilation failed - missing system libraries\n")
        cat("\nRun: install_linux_deps()\n")
        cat("for commands to install required system libraries,\n")
        cat("then try setup_project() again.\n")
      } else {
        cat("\n❌ Installation error:\n")
        cat(e$message, "\n")
        if (sys_name == "Windows") {
          cat("\nTry: setup_project(binary_only = TRUE)\n")
        }
      }
    })
    
    # Reset package type if changed
    if (binary_only) {
      options(pkgType = "both")  # Reset to default
    }
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
    
    script_path <- "scripts/db.R"
    if (file.exists(script_path)) {
      cat("Opening:", script_path, "\n")
      if (requireNamespace("rstudioapi", quietly = TRUE) && 
          rstudioapi::isAvailable()) {
        invisible(rstudioapi::navigateToFile(script_path))
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
    
    # Platform-specific checks
    if (sys_name == "Windows") {
      cat("\n🪟 Windows build tools:\n")
      if (Sys.which("make") != "") {
        cat("   ✔ Rtools detected (make available)\n")
      } else {
        cat("   ⚠️  Rtools not detected\n")
        cat("   Run install_windows_tools() for installation info\n")
      }
    } else if (sys_name == "Linux") {
      cat("\n🐧 Linux build tools:\n")
      if (system2("which", args = "gcc", stdout = FALSE, stderr = FALSE) == 0) {
        cat("   ✔ GCC compiler found\n")
      } else {
        cat("   ⚠️  GCC not found - install build-essential\n")
      }
      cat("   Run install_linux_deps() for system requirements\n")
    }
    
    # Working directory
    cat("\n📁 Working directory:\n   ", getwd(), "\n")
    
    # renv status
    cat("\n📦 Package management (renv):\n")
    if (!requireNamespace("renv", quietly = TRUE)) {
      cat("   ❌ renv not installed\n")
    } else {
      renv_ver <- as.character(packageVersion("renv"))
      cat("   ✔ renv version:", renv_ver, "\n")
      
      if (file.exists("renv.lock")) {
        cat("   ✔ renv.lock found\n")
        .check_dependencies(silent = FALSE)
      } else {
        cat("   ❌ renv.lock not found\n")
      }
    }
    
    # Project files
    cat("\n📄 Project files:\n")
    files <- c(
      "scripts/db.R",
      "renv.lock",
      ".Rprofile",
      "database_albatross_recollections.Rproj"
    )
    for (f in files) {
      if (file.exists(f)) {
        cat("   ✔", f, "\n")
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
  
  # Platform-specific function assignment
  if (sys_name == "Windows") {
    assign("install_windows_tools", install_windows_tools, envir = .GlobalEnv)
  } else if (sys_name == "Linux") {
    assign("install_linux_deps", install_linux_deps, envir = .GlobalEnv)
  }
  
  # Display instructions based on status
  cat("\n------------------------------------------------------------\n")
  
  if (!renv_available) {
    cat(" 🔧 INITIAL SETUP REQUIRED\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run: setup_project()\n\n")
    
    if (sys_name == "Windows") {
      cat(" Windows: If you see 'make not found' errors:\n")
      cat("   • Run: install_windows_tools() for Rtools info, OR\n")
      cat("   • Run: setup_project(binary_only = TRUE) for pre-built packages\n\n")
    } else if (sys_name == "Linux") {
      cat(" Linux: You may need system libraries.\n")
      cat("   • Run: install_linux_deps() for requirements\n\n")
    }
  } else if (!deps_ok && lockfile_exists) {
    cat(" 📦 PACKAGE INSTALLATION NEEDED\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run: setup_project()\n\n")
    
    if (sys_name == "Windows" && Sys.which("make") == "") {
      cat(" ⚠️  Rtools not detected. Options:\n")
      cat("   1. setup_project(binary_only = TRUE)  # Use pre-built packages\n")
      cat("   2. install_windows_tools()  # Get Rtools installation guide\n\n")
    } else if (sys_name == "Linux") {
      cat(" If compilation fails:\n")
      cat("   • Run: install_linux_deps() for system requirements\n\n")
    }
  } else if (deps_ok) {
    cat(" ✅ PROJECT READY\n")
    cat("------------------------------------------------------------\n\n")
    cat(" Run: open_main_script()\n\n")
  }
  
  cat(" Available commands:\n")
  cat("   • setup_project()     - Install/update R packages\n")
  
  if (sys_name == "Windows") {
    cat("   • setup_project(binary_only = TRUE) - Use pre-built packages\n")
    cat("   • install_windows_tools() - Rtools installation guide\n")
  } else if (sys_name == "Linux") {
    cat("   • install_linux_deps() - System library requirements\n")
  }
  
  cat("   • open_main_script()  - Open main script\n")
  cat("   • check_setup()       - Show detailed status\n")
  cat("\n============================================================\n\n")
}

# Clean up any temporary variables
rm(renv_activated)