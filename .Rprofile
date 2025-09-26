# .Rprofile - Project setup with system dependency checking
# Modified to work when sourced from parent directories

# Determine the project directory based on where this .Rprofile is located
.determine_project_dir <- function() {
  # Try to find where this .Rprofile was sourced from
  # This works by looking for the .Rprofile file itself
  
  # First check if we're already in the right directory
  if (file.exists("database_albatross_recollections.Rproj")) {
    return(getwd())
  }
  
  # Check if .Rprofile exists in current directory
  if (file.exists(".Rprofile")) {
    # Read it to see if it's the right one (contains our project name)
    profile_content <- readLines(".Rprofile", n = 50, warn = FALSE)
    if (any(grepl("database_albatross_recollections", profile_content))) {
      return(getwd())
    }
  }
  
  # Look in subdirectories for the project
  subdirs <- list.dirs(path = ".", recursive = FALSE, full.names = TRUE)
  for (dir in subdirs) {
    proj_file <- file.path(dir, "database_albatross_recollections.Rproj")
    rprofile <- file.path(dir, ".Rprofile")
    if (file.exists(proj_file) && file.exists(rprofile)) {
      return(normalizePath(dir))
    }
  }
  
  # If we can't find it, check if we're being sourced with a full path
  # This requires checking the call stack
  if (sys.nframe() > 0) {
    for (i in sys.nframe():1) {
      call_info <- sys.call(i)
      if (length(call_info) > 1 && deparse(call_info[[1]]) == "source") {
        source_file <- as.character(call_info[[2]])
        if (grepl("\\.Rprofile$", source_file)) {
          return(normalizePath(dirname(source_file)))
        }
      }
    }
  }
  
  # Last resort: ask the user
  return(NULL)
}

# Store original working directory to potentially restore later
.original_wd <- getwd()
.project_dir <- .determine_project_dir()

# If we found the project directory and it's different from current, change to it
if (!is.null(.project_dir) && .project_dir != getwd()) {
  setwd(.project_dir)
  .changed_dir <- TRUE
} else {
  .changed_dir <- FALSE
}

# Suppress renv activation messages more safely
renv_activated <- FALSE
# Use renv::load() if we're not in the project directory, source activate.R if we are
if (!is.null(.project_dir)) {
  # We found the project directory
  if (.changed_dir) {
    # We're NOT in the project directory, use renv::load with the path
    if (requireNamespace("renv", quietly = TRUE)) {
      tryCatch({
        invisible(utils::capture.output({
          suppressMessages(suppressWarnings({
            renv::load(.project_dir)
            renv_activated <- TRUE
          }))
        }))
      }, error = function(e) {
        # If renv::load fails, try changing directory and sourcing
        if (file.exists(file.path(.project_dir, "renv/activate.R"))) {
          old_wd <- getwd()
          setwd(.project_dir)
          tryCatch({
            invisible(utils::capture.output({
              suppressMessages(suppressWarnings({
                source("renv/activate.R")
                renv_activated <- TRUE
              }))
            }))
          }, error = function(e2) {
            renv_activated <- FALSE
          }, finally = {
            setwd(old_wd)
          })
        }
      })
    }
  } else {
    # We're already in the project directory, use the normal activation
    if (file.exists("renv/activate.R")) {
      tryCatch({
        invisible(utils::capture.output({
          suppressMessages(suppressWarnings({
            source("renv/activate.R")
            renv_activated <- TRUE
          }))
        }))
      }, error = function(e) {
        renv_activated <- FALSE
      })
    }
  }
} else {
  # Project directory not found, try activate.R if it exists in current directory
  if (file.exists("renv/activate.R")) {
    tryCatch({
      invisible(utils::capture.output({
        suppressMessages(suppressWarnings({
          source("renv/activate.R")
          renv_activated <- TRUE
        }))
      }))
    }, error = function(e) {
      renv_activated <- FALSE
    })
  }
}

# Always run our setup regardless of renv status
if (interactive()) {
  
  # Ensure clean namespace before loading
  tryCatch({
    if ("stringr" %in% loadedNamespaces()) {
      unloadNamespace("stringr")
    }
    if ("janitor" %in% loadedNamespaces()) {
      unloadNamespace("janitor")
    }
  }, error = function(e) {
    # If unloading fails, we'll handle it
    NULL
  })

  # Clear line and start our output
  cat("\n============================================================\n")
  cat(" PROJECT: database_albatross_recollections\n")
  cat("============================================================\n")
  
  # Set working directory
  tryCatch({
    if (!is.null(.project_dir)) {
      if (.changed_dir) {
        cat("\n📁 Working directory changed to project folder\n")
        cat("   From: ", .original_wd, "\n")
        cat("   To:   ", .project_dir, "\n")
      } else {
        cat("\n📁 Working directory confirmed\n")
        cat("   ", getwd(), "\n")
      }
    } else {
      cat("\n⚠️  Could not determine project directory\n")
      cat("   Current directory: ", getwd(), "\n")
      cat("   Please navigate to the database_albatross_recollections folder\n")
      # Try to provide helpful guidance
      if (!file.exists("database_albatross_recollections.Rproj")) {
        cat("   Looking for subdirectories...\n")
        subdirs <- list.dirs(path = ".", recursive = FALSE, full.names = FALSE)
        proj_dirs <- subdirs[grepl("database|albatross", subdirs, ignore.case = TRUE)]
        if (length(proj_dirs) > 0) {
          cat("   Possible project directories found:\n")
          for (dir in proj_dirs) {
            cat("     • ", dir, "\n")
          }
          cat("   Try: setwd('", proj_dirs[1], "') then source('.Rprofile')\n", sep = "")
        }
      }
    }
  }, error = function(e) {
    cat("\n📁 Working directory: ", getwd(), "\n")
  })
  
  # Only proceed with checks if we're in the right directory
  if (!is.null(.project_dir) || file.exists("database_albatross_recollections.Rproj")) {
    
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
        cat("   ✓ Rtools detected\n")
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
        cat("   ✓ Build tools detected\n")
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
        cat("   ✓ Development tools detected\n")
      }
      
      # Critical: Check for gfortran and its source
      .check_gfortran_mac <- function() {
        gfortran_path <- Sys.which("gfortran")
        
        if (gfortran_path == "") {
          return(list(installed = FALSE, source = "none", path = ""))
        }
        
        # Check if it's from Homebrew (problematic) or CRAN (good)
        is_homebrew <- grepl("/opt/homebrew|/usr/local/Cellar|/usr/local/bin/gfortran", gfortran_path)
        
        # Try to check version
        version_output <- suppressWarnings(system2("gfortran", "--version", stdout = TRUE, stderr = FALSE))
        
        return(list(
          installed = TRUE,
          source = if(is_homebrew) "homebrew" else "cran",
          path = gfortran_path,
          version = version_output[1]
        ))
      }
      
      gfortran_info <- .check_gfortran_mac()
      
      if (!gfortran_info$installed) {
        cat("   ⚠️  gfortran NOT found (REQUIRED for many R packages)\n")
        cat("      Download from: https://cran.r-project.org/bin/macosx/tools/\n")
        cat("      Choose the gfortran version for your macOS\n")
      } else if (gfortran_info$source == "homebrew") {
        cat("   ⚠️  gfortran detected from Homebrew at:", gfortran_info$path, "\n")
        cat("      This often causes R package compilation failures!\n")
        cat("      You need the CRAN version instead:\n")
        cat("      1. Remove Homebrew gfortran: brew uninstall gcc\n")
        cat("      2. Download from: https://cran.r-project.org/bin/macosx/tools/\n")
        cat("      3. Install the .pkg file and restart R\n")
      } else {
        cat("   ✓ gfortran detected (CRAN version)\n")
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
      if (!requireNamespace("renv", quietly = TRUE) || !file.exists("renv.lock")) {
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
      } else if (r_version >= "4.3") {
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
    
    install_macos_deps <- function() {
      if (Sys.info()["sysname"] != "Darwin") {
        cat("This function is only for macOS systems.\n")
        return(invisible(NULL))
      }
      
      cat("\n🍎 MACOS SYSTEM DEPENDENCIES\n")
      cat("===============================\n")
      
      # Check architecture
      arch_info <- system2("uname", "-m", stdout = TRUE)
      is_arm <- grepl("arm64", arch_info)
      
      cat("\n📱 System Architecture:", if(is_arm) "Apple Silicon (M1/M2/M3)" else "Intel", "\n")
      
      # First and most important: Check gfortran
      cat("\n🔴 CRITICAL: gfortran Check\n")
      cat("────────────────────────────\n")
      
      gfortran_path <- Sys.which("gfortran")
      
      if (gfortran_path == "") {
        cat("❌ gfortran NOT FOUND - This is required!\n\n")
        cat("INSTALL gfortran (REQUIRED):\n")
        cat("1. Go to: https://cran.r-project.org/bin/macosx/tools/\n")
        cat("2. Download the appropriate gfortran installer:\n")
        if (is_arm) {
          cat("   • For Apple Silicon: gfortran-12.2-universal.pkg\n")
        } else {
          cat("   • For Intel Macs: gfortran-12.2-universal.pkg\n")
        }
        cat("3. Run the .pkg installer\n")
        cat("4. Restart R/RStudio completely\n")
        cat("\n⚠️  DO NOT install gfortran via Homebrew (brew install gcc)\n")
        cat("   Homebrew's gfortran causes R package compilation failures!\n")
      } else if (grepl("/opt/homebrew|/usr/local/Cellar", gfortran_path)) {
        cat("⚠️  WARNING: gfortran from Homebrew detected at:", gfortran_path, "\n")
        cat("\nThis version often causes R package failures!\n")
        cat("TO FIX:\n")
        cat("1. Remove Homebrew's gcc/gfortran:\n")
        cat("   brew uninstall gcc\n")
        cat("2. Install CRAN's gfortran:\n")
        cat("   • Go to: https://cran.r-project.org/bin/macosx/tools/\n")
        cat("   • Download gfortran-12.2-universal.pkg\n")
        cat("   • Run the installer\n")
        cat("3. Restart R/RStudio\n")
      } else {
        cat("✅ gfortran found at:", gfortran_path, "\n")
        cat("   Appears to be CRAN version (good!)\n")
      }
      
      cat("\n\n📦 Other Development Tools\n")
      cat("──────────────────────────\n")
      
      # Check Xcode Command Line Tools
      if (system2("which", args = "clang", stdout = FALSE, stderr = FALSE) != 0) {
        cat("❌ Xcode Command Line Tools not found\n")
        cat("   Install with: xcode-select --install\n\n")
      } else {
        cat("✅ Xcode Command Line Tools installed\n")
      }
      
      # Check Homebrew
      brew_installed <- system2("which", args = "brew", stdout = FALSE, stderr = FALSE) == 0
      if (!brew_installed) {
        cat("⚠️  Homebrew not found (optional but recommended)\n")
        cat("   Install from: https://brew.sh\n")
        cat("   /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n")
      } else {
        cat("✅ Homebrew installed\n")
      }
      
      if (brew_installed) {
        cat("\n\n📚 Additional Libraries (via Homebrew)\n")
        cat("──────────────────────────────────────\n")
        cat("These are optional but help with specific R packages:\n\n")
        
        cat("brew install \\\n")
        cat("  pkg-config \\\n")
        cat("  openssl \\\n")
        cat("  libxml2 \\\n")
        cat("  libgit2 \\\n")
        cat("  freetype \\\n")
        cat("  fontconfig \\\n")
        cat("  cairo \\\n")
        cat("  harfbuzz \\\n")
        cat("  fribidi \\\n")
        cat("  glpk \\\n")
        cat("  gmp \\\n")
        cat("  mpfr \\\n")
        cat("  icu4c \\\n")
        cat("  pandoc\n")
        
        cat("\n⚠️  IMPORTANT: Do NOT install gcc or gfortran via Homebrew!\n")
      }
      
      cat("\n\n🔧 Environment Variables\n")
      cat("────────────────────────\n")
      cat("If R can't find libraries, create/edit ~/.Renviron:\n\n")
      
      if (is_arm) {
        cat("# For Apple Silicon Macs\n")
        cat("PKG_CONFIG_PATH=\"/opt/homebrew/lib/pkgconfig:/opt/R/arm64/lib/pkgconfig\"\n")
        cat("LDFLAGS=\"-L/opt/homebrew/lib -L/opt/R/arm64/lib\"\n")
        cat("CPPFLAGS=\"-I/opt/homebrew/include -I/opt/R/arm64/include\"\n")
      } else {
        cat("# For Intel Macs\n")
        cat("PKG_CONFIG_PATH=\"/usr/local/lib/pkgconfig:/opt/R/x86_64/lib/pkgconfig\"\n")
        cat("LDFLAGS=\"-L/usr/local/lib -L/opt/R/x86_64/lib\"\n")
        cat("CPPFLAGS=\"-I/usr/local/include -I/opt/R/x86_64/include\"\n")
      }
      
      cat("\n\n📋 INSTALLATION ORDER\n")
      cat("────────────────────\n")
      cat("1. Install gfortran from CRAN (if not done)\n")
      cat("2. Install Xcode Command Line Tools (if not done)\n")
      cat("3. Restart R/RStudio\n")
      cat("4. Run: setup_project()\n")
      cat("5. If specific packages fail, install Homebrew libraries\n")
      
      cat("\n\n🆘 TROUBLESHOOTING\n")
      cat("─────────────────\n")
      cat("• Matrix package fails: Usually means wrong gfortran\n")
      cat("• stringi package fails: May need to reinstall with:\n")
      cat("  install.packages('stringi', type='source')\n")
      cat("• Can't find gfortran after install: Restart R/RStudio\n")
      cat("• Still having issues: Check https://cran.r-project.org/bin/macosx/\n")
    }
    
    setup_project <- function(binary_only = FALSE) {
      cat("\n🔧 Setting up project environment...\n\n")
      
      # Ensure we're in the project directory
      if (!file.exists("renv.lock")) {
        if (!is.null(.project_dir)) {
          setwd(.project_dir)
          cat("Changed to project directory:", .project_dir, "\n")
        } else {
          cat("❌ Error: Not in project directory and cannot locate it\n")
          cat("   Please navigate to the database_albatross_recollections folder\n")
          return(invisible(NULL))
        }
      }
      
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
      } else if (sys_name == "Darwin") {
        # Critical check for gfortran on macOS
        gfortran_path <- Sys.which("gfortran")
        if (gfortran_path == "") {
          cat("🔴 CRITICAL: gfortran not found!\n")
          cat("   Many R packages (including Matrix) require gfortran.\n")
          cat("   Run: install_macos_deps() for installation instructions\n")
          cat("   Then restart R and try again.\n\n")
          
          response <- readline("Continue anyway? (y/n): ")
          if (tolower(response) != "y") {
            cat("Setup cancelled. Please install gfortran first.\n")
            return(invisible(NULL))
          }
        } else if (grepl("/opt/homebrew|/usr/local/Cellar", gfortran_path)) {
          cat("⚠️  WARNING: Homebrew's gfortran detected!\n")
          cat("   This often causes compilation failures.\n")
          cat("   Run: install_macos_deps() to fix this\n\n")
        }
        
        cat("📋 NOTE: On macOS, some packages need system libraries.\n")
        cat("   If installation fails, run: install_macos_deps()\n\n")
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
        return(invisible(NULL))
      }
      
      # Restore packages
      cat("Step 2: Installing R packages (this may take 5-10 minutes)...\n\n")
      
      # Try to restore, catching common errors
      tryCatch({
        renv::restore(prompt = FALSE)
        cat("\n✅ Setup complete!\n")
        cat("   Please restart R (Session → Restart R or Ctrl+Shift+F10)\n")
        cat("   Then run: pire_database() or update_database()\n")
      }, error = function(e) {
        error_msg <- tolower(e$message)
        
        if (grepl("make.*not found", error_msg) && sys_name == "Windows") {
          cat("\n❌ Compilation failed - 'make' not found\n\n")
          cat("This means Rtools is not installed. You have two options:\n\n")
          cat("OPTION 1: Install Rtools (recommended)\n")
          cat("   Run: install_windows_tools()\n")
          cat("   Follow the instructions, then run setup_project() again\n\n")
          cat("OPTION 2: Use pre-built binaries (easier but may be older versions)\n")
          cat("   Run: setup_project(binary_only = TRUE)\n\n")
        } else if (grepl("gfortran|fortran", error_msg) && sys_name == "Darwin") {
          cat("\n❌ Compilation failed - gfortran issue\n")
          cat("\nThis is a common macOS problem. To fix:\n")
          cat("1. Run: install_macos_deps()\n")
          cat("2. Follow the gfortran installation instructions\n")
          cat("3. Restart R/RStudio completely\n")
          cat("4. Run: setup_project() again\n")
        } else if (grepl("(libcurl|libssl|libgit2|libxml2|compilation failed|undefined symbol)", error_msg)) {
          cat("\n❌ Compilation failed - missing system libraries\n")
          if (sys_name == "Linux") {
            cat("\nRun: install_linux_deps()\n")
          } else if (sys_name == "Darwin") {
            cat("\nRun: install_macos_deps()\n")
          }
          cat("for commands to install required system libraries,\n")
          cat("then try setup_project() again.\n")
        } else {
          cat("\n❌ Installation error:\n")
          cat(e$message, "\n")
          if (sys_name == "Windows") {
            cat("\nTry: setup_project(binary_only = TRUE)\n")
          } else if (sys_name == "Darwin") {
            cat("\nTry: install_macos_deps() for system dependencies\n")
            cat("Pay special attention to the gfortran section!\n")
          }
        }
      })
      
      # Reset package type if changed
      if (binary_only) {
        options(pkgType = "both")  # Reset to default
      }
    }
    
    pire_database <- function() {

      original_dir <- getwd()

      # Ensure we're in the project directory
      if (!file.exists("scripts/functions.R")) {
        if (!is.null(.project_dir)) {
          setwd(.project_dir)
        } else {
          cat("❌ Error: Not in project directory\n")
          cat("   Please navigate to the database_albatross_recollections folder\n")
          return(invisible(NULL))
        }
      }
      
      # Quick dependency check if renv is available
      if (requireNamespace("renv", quietly = TRUE) && file.exists("renv.lock")) {
        if (!.check_dependencies(silent = TRUE)) {
          cat("\n⚠️  Some packages are missing!\n")
          cat("   Run setup_project() first, then restart R.\n")
          return(invisible(NULL))
        }
      }
      
      #The first time this is called it sources in the functions and runs itself. 
      #After it is replaced with the main function
        # Use tryCatch to ensure we return to original directory even if there's an error
      tryCatch({
        # The first time this is called it sources in the functions and runs itself. 
        # After it is replaced with the main function
        source("scripts/functions.R")
        
        # Call the actual pire_database function from the sourced file
        result <- pire_database()
        
        # Return to the original directory
        setwd(original_dir)
        cat("\n📁 Returned to original directory:", original_dir, "\n")
        
        # Return whatever the pire_database function returned
        return(result)
        
      }, error = function(e) {
        # If there's an error, still return to the original directory
        setwd(original_dir)
        cat("\n📁 Returned to original directory after error:", original_dir, "\n")
        stop(e)
      })
    }
    
    update_database <- function(integrate_files = TRUE) {

      original_dir <- getwd()

      # Ensure we're in the project directory
      if (!file.exists("scripts/functions.R")) {
        if (!is.null(.project_dir)) {
          setwd(.project_dir)
        } else {
          cat("❌ Error: Not in project directory\n")
          cat("   Please navigate to the database_albatross_recollections folder\n")
          return(invisible(NULL))
        }
      }
      
      # Quick dependency check if renv is available
      if (requireNamespace("renv", quietly = TRUE) && file.exists("renv.lock")) {
        if (!.check_dependencies(silent = TRUE)) {
          cat("\n⚠️  Some packages are missing!\n")
          cat("   Run setup_project() first, then restart R.\n")
          return(invisible(NULL))
        }
      }
      
      #The first time this is called it sources in the functions and runs itself. 
      #After it is replaced with the main function
      # Use tryCatch to ensure we return to original directory even if there's an error
      tryCatch({
        # The first time this is called it sources in the functions and runs itself. 
        # After it is replaced with the main function
        source("scripts/functions.R")
        
        # Call the actual update_database function from the sourced file
        result <- update_database(integrate_files)
        
        # Return to the original directory
        setwd(original_dir)
        cat("\n📁 Returned to original directory:", original_dir, "\n")
        
        # Return whatever the update_database function returned
        return(result)
        
      }, error = function(e) {
        # If there's an error, still return to the original directory
        setwd(original_dir)
        cat("\n📁 Returned to original directory after error:", original_dir, "\n")
        stop(e)
      })
    }
    
    output_geome_metadata <- function(extraction_ids, output_path = NULL, 
                                      geome_ids = NULL, sequence_ids = NULL) {

      original_dir <- getwd()

      # Ensure we're in the project directory
      if (!file.exists("scripts/functions.R")) {
        if (!is.null(.project_dir)) {
          setwd(.project_dir)
        } else {
          cat("❌ Error: Not in project directory\n")
          cat("   Please navigate to the database_albatross_recollections folder\n")
          return(invisible(NULL))
        }
      }
      
      # Quick dependency check if renv is available
      if (requireNamespace("renv", quietly = TRUE) && file.exists("renv.lock")) {
        if (!.check_dependencies(silent = TRUE)) {
          cat("\n⚠️  Some packages are missing!\n")
          cat("   Run setup_project() first, then restart R.\n")
          return(invisible(NULL))
        }
      }
      
      #The first time this is called it sources in the functions and runs itself. 
      #After it is replaced with the main function
      # Use tryCatch to ensure we return to original directory even if there's an error
      tryCatch({
        # The first time this is called it sources in the functions and runs itself. 
        # After it is replaced with the main function
        source("scripts/functions.R")

        # Return to the original directory
        setwd(original_dir)
        cat("\n📁 Returned to original directory:", original_dir, "\n")

        # Call the actual update_database function from the sourced file
        result <- output_geome_metadata(extraction_ids, output_path, 
                                      geome_ids, sequence_ids)
                
        # Return whatever the update_database function returned
        return(result)
        
      }, error = function(e) {
        # If there's an error, still return to the original directory
        setwd(original_dir)
        cat("\n📁 Returned to original directory after error:", original_dir, "\n")
        stop(e)
      })
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
          cat("   ✓ Rtools detected (make available)\n")
        } else {
          cat("   ⚠️  Rtools not detected\n")
          cat("   Run install_windows_tools() for installation info\n")
        }
        
      } else if (sys_name == "Linux") {
        cat("\n🐧 Linux build tools:\n")
        if (system2("which", args = "gcc", stdout = FALSE, stderr = FALSE) == 0) {
          cat("   ✓ GCC compiler found\n")
        } else {
          cat("   ⚠️  GCC not found - install build-essential\n")
        }
        
        # Check for gfortran on Linux
        if (Sys.which("gfortran") != "") {
          cat("   ✓ gfortran found\n")
        } else {
          cat("   ⚠️  gfortran not found - install gfortran\n")
        }
        cat("   Run install_linux_deps() for system requirements\n")
        
      } else if (sys_name == "Darwin") {
        cat("\n🍎 macOS build tools:\n")
        
        # Check architecture
        arch_info <- system2("uname", "-m", stdout = TRUE, stderr = FALSE)
        is_arm <- grepl("arm64", arch_info)
        cat("   Architecture:", if(is_arm) "Apple Silicon (M1/M2/M3)" else "Intel", "\n")
        
        # Check Xcode Command Line Tools
        if (system2("which", args = "clang", stdout = FALSE, stderr = FALSE) == 0) {
          cat("   ✓ Xcode Command Line Tools found\n")
        } else {
          cat("   ⚠️  Xcode Command Line Tools not found\n")
          cat("      Install with: xcode-select --install\n")
        }
        
        # Critical: Check gfortran
        gfortran_path <- Sys.which("gfortran")
        if (gfortran_path == "") {
          cat("   ❌ gfortran NOT FOUND (CRITICAL!)\n")
          cat("      Download from: https://cran.r-project.org/bin/macosx/tools/\n")
          cat("      DO NOT use Homebrew's gfortran!\n")
        } else {
          # Check if it's from Homebrew (problematic)
          if (grepl("/opt/homebrew|/usr/local/Cellar|/usr/local/bin/gfortran", gfortran_path)) {
            cat("   ⚠️  gfortran found (Homebrew version - MAY CAUSE ISSUES!)\n")
            cat("      Path:", gfortran_path, "\n")
            cat("      Consider installing CRAN version instead\n")
          } else {
            cat("   ✓ gfortran found (appears to be CRAN version)\n")
            cat("      Path:", gfortran_path, "\n")
          }
          
          # Try to get version
          version_check <- suppressWarnings(
            system2("gfortran", "--version", stdout = TRUE, stderr = FALSE)[1]
          )
          if (!is.na(version_check) && length(version_check) > 0) {
            cat("      Version:", version_check, "\n")
          }
        }
        
        # Check Homebrew
        if (system2("which", args = "brew", stdout = FALSE, stderr = FALSE) == 0) {
          cat("   ✓ Homebrew found\n")
          
          # Check if problematic gcc is installed via Homebrew
          gcc_check <- suppressWarnings(
            system2("brew", args = c("list", "--versions", "gcc"), 
                    stdout = TRUE, stderr = FALSE)
          )
          if (length(gcc_check) > 0 && !grepl("Error", gcc_check[1])) {
            cat("   ⚠️  Homebrew gcc detected - may conflict with R's gfortran!\n")
          }
        } else {
          cat("   ⚠️  Homebrew not found (optional for additional libraries)\n")
          cat("      Install from: https://brew.sh\n")
        }
        
        cat("   Run install_macos_deps() for detailed requirements\n")
      }
      
      # Working directory
      cat("\n📁 Working directory:\n   ", getwd(), "\n")
      if (.changed_dir) {
        cat("   (Changed from:", .original_wd, ")\n")
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
          
          # Show dependency status
          .check_dependencies(silent = FALSE)
          
          # Additional check for commonly problematic packages on macOS
          if (sys_name == "Darwin") {
            problematic_pkgs <- c("Matrix", "igraph", "stringi")
            installed_pkgs <- rownames(installed.packages())
            
            cat("\n   macOS-sensitive packages:\n")
            for (pkg in problematic_pkgs) {
              if (pkg %in% installed_pkgs) {
                cat("     ✓", pkg, "installed\n")
              } else {
                cat("     ✗", pkg, "not installed", 
                    if(pkg == "Matrix") "(often fails with wrong gfortran)" else "", "\n")
              }
            }
          }
        } else {
          cat("   ❌ renv.lock not found\n")
        }
      }
      
      # Project files
      cat("\n📄 Project files:\n")
      files <- c(
        "scripts/functions.R",
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
      
      # Environment variables check for macOS
      if (sys_name == "Darwin") {
        cat("\n🔧 Environment variables:\n")
        
        pkg_config <- Sys.getenv("PKG_CONFIG_PATH")
        if (pkg_config != "") {
          cat("   ✓ PKG_CONFIG_PATH set\n")
        } else {
          cat("   ⚠️  PKG_CONFIG_PATH not set (usually OK)\n")
        }
        
        # Check if common R configuration exists
        if (file.exists("~/.Renviron")) {
          cat("   ✓ ~/.Renviron exists\n")
        } else {
          cat("   ℹ️  ~/.Renviron not found (OK unless you have path issues)\n")
        }
      }
      
      cat("\n========================\n")
      
      # Final recommendations
      cat("\n🎯 NEXT STEPS:\n")
      
      if (sys_name == "Darwin" && Sys.which("gfortran") == "") {
        cat("   1. CRITICAL: Install gfortran from CRAN first!\n")
        cat("      Run: install_macos_deps() for instructions\n")
      }
      
      if (!requireNamespace("renv", quietly = TRUE) || 
          (file.exists("renv.lock") && !.check_dependencies(silent = TRUE))) {
        cat("   • Run: setup_project() to install packages\n")
      } else {
        cat("   • All packages installed - ready to use!\n")
        cat("   • Run: pire_database() or update_database()\n")
      }
      
      cat("\n========================\n")
    }
    
    return_to_original <- function() {
      if (.changed_dir && !is.null(.original_wd)) {
        setwd(.original_wd)
        cat("Returned to original directory:", .original_wd, "\n")
        rm(.original_wd, .changed_dir, envir = .GlobalEnv)
      } else {
        cat("Already in original directory\n")
      }
    }
    
    # Make functions globally available
    assign("setup_project", setup_project, envir = .GlobalEnv)
    assign("check_setup", check_setup, envir = .GlobalEnv)
    assign("return_to_original", return_to_original, envir = .GlobalEnv)
    
    if(deps_ok){
      assign("pire_database", pire_database, envir = .GlobalEnv)  
      assign("update_database", update_database, envir = .GlobalEnv) 
    }
    
    # Store directory variables in global environment
    assign(".original_wd", .original_wd, envir = .GlobalEnv)
    assign(".project_dir", .project_dir, envir = .GlobalEnv)
    assign(".changed_dir", .changed_dir, envir = .GlobalEnv)
    
    # Platform-specific function assignment
    if (sys_name == "Windows") {
      assign("install_windows_tools", install_windows_tools, envir = .GlobalEnv)
    } else if (sys_name == "Linux") {
      assign("install_linux_deps", install_linux_deps, envir = .GlobalEnv)
    } else if (sys_name == "Darwin") {
      assign("install_macos_deps", install_macos_deps, envir = .GlobalEnv)
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
      } else if (sys_name == "Darwin") {
        cat(" macOS: You may need system libraries.\n")
        cat("   • Run: install_macos_deps() for requirements\n\n")
      }
      rm('pire_database', 'update_database')
    } else if (!deps_ok && lockfile_exists) {
      cat(" 📦 PACKAGE INSTALLATION NEEDED\n")
      cat("------------------------------------------------------------\n\n")
      rm('pire_database', 'update_database')
      
      if (sys_name == "Windows" && Sys.which("make") == "") {
        cat(" ⚠️  Rtools not detected.\n")
        cat("   • Run: install_windows_tools()  # Get Rtools installation guide\n\n")
        cat("   After installing Rtools restart R and run setup_project() to install R packages")
        rm('install_linux_deps', 'deps_ok', 'lockfile_exists', 'renv_available')
        rm('sys_name', 'check_rtools', 'check_setup', 'setup_project', 'install_macos_deps')
      } else if (sys_name == "Linux") {
        cat(" Run: setup_project()\n\n")
        cat(" If compilation fails:\n")
        cat("   • Run: install_linux_deps() for system requirements\n\n")
        rm('install_windows_tools', 'install_macos_deps')
      } else if (sys_name == "Darwin") {
        cat(" Run: setup_project()\n\n")
        cat(" If compilation fails:\n")
        cat("   • Run: install_macos_deps() for requirements\n\n")
        rm('install_linux_deps', 'install_windows_tools')
      } else {
        cat(" Run: setup_project()\n\n")
        rm('install_linux_deps', 'install_windows_tools', 'install_macos_deps')
      }
    } else if (deps_ok) {
      cat(" ✅ PROJECT READY\n")
      cat(" ┌────────────────────────────────────────────────────┐\n")
      cat(" 💡 QUICK START:\n")
      cat(sprintf("    • %-25s Run: %s\n", "Using the database?", "pire_database()"))
      cat(sprintf("    • %-25s Run: %s\n", "Updating the database?", "update_database()"))
      cat(" └────────────────────────────────────────────────────┘\n")
      if (.changed_dir) {
        #cat(sprintf("    • %-25s Run: %s\n", "Return to original dir?", "return_to_original()"))
        return_to_original()
      }
      cat("\n")
      if(sys_name == "Windows"){
        rm('check_rtools')
      } else if(sys_name == "Linux"){
        rm('libs_to_check', 'lib', 'renv_activated', 'check_system_lib')
      } else if(sys_name == "Darwin"){
        rm('arch_info', 'is_arm', 'version_check', 'gcc_check', 'brew_installed')
      }
      rm('install_linux_deps', 'install_windows_tools', 'check_setup', 'setup_project')
      rm('sys_name', 'renv_available', 'lockfile_exists', 'deps_ok', 'install_macos_deps')
      rm('return_to_original')
    }
  } else {
    cat("\n⚠️  Could not locate the project directory\n")
    cat("Please ensure you're in or above the database_albatross_recollections folder\n")
  }
}

# Clean up any temporary variables except directory tracking
if (exists("renv_activated")) rm(renv_activated)
if (exists(".determine_project_dir")) rm(.determine_project_dir)