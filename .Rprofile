source("renv/activate.R")

# .Rprofile - Ensures proper environment setup for the project

if (interactive()) {
  
  # Set working directory to project root (where .Rproj file is)
  # This ensures all paths work correctly regardless of how R/RStudio was opened
  if (exists(".rs.getProjectDirectory")) {
    # RStudio-specific way to get project directory
    project_dir <- .rs.getProjectDirectory()
    setwd(project_dir)
  } else if (file.exists("database_albatross_recollections.Rproj")) {
    # We're already in the right directory
    project_dir <- getwd()
  } else {
    # Try to find the project directory
    project_dir <- here::here()
    setwd(project_dir)
  }
  
  # Display startup message with instructions
  cat("\n", rep("=", 60), sep = "")
  cat("\n PROJECT: database_albatross_recollections")
  cat("\n", rep("=", 60), sep = "")
  
  # Verify working directory
  cat("\n\n📁 Working directory set to project root:")
  cat("\n   ", getwd())
  
  # Verify renv is active
  cat("\n\n📦 Package library (renv):")
  cat("\n   ", .libPaths()[1])
  
  # Check if critical files exist
  cat("\n\n✓ Checking project structure:")
  
  critical_files <- c(
    "scripts/assemble_db.R",
    "renv.lock",
    "database_albatross_recollections.Rproj"
  )
  
  for (file in critical_files) {
    if (file.exists(file)) {
      cat("\n   ✓", file, "found")
    } else {
      cat("\n   ✗", file, "NOT FOUND")
    }
  }
  
  # Clear instructions for users
  cat("\n\n", rep("-", 60), sep = "")
  cat("\n 🚀 TO GET STARTED:")
  cat("\n", rep("-", 60), sep = "")
  cat("\n\n 1. Open the main script:")
  cat("\n    • In RStudio: File → Open File → scripts/assemble_db.R")
  cat("\n    • Or run: file.edit('scripts/assemble_db.R')")
  cat("\n\n 2. The script will use the project root as working directory")
  cat("\n    All paths in scripts should be relative to:", basename(getwd()))
  cat("\n\n 3. All packages will be loaded from renv library")
  cat("\n", rep("=", 60), sep = "")
  cat("\n\n")
  
  # Optional: Create a helper function for users
  open_main_script <- function() {
    if (file.exists("scripts/assemble_db.R")) {
      file.edit("scripts/assemble_db.R")
    } else {
      stop("scripts/assemble_db.R not found. Please check your project structure.")
    }
  }
  
  # Make the function available globally
  assign("open_main_script", open_main_script, envir = .GlobalEnv)
  
  cat("💡 Tip: Type open_main_script() to open the main script\n\n")
}