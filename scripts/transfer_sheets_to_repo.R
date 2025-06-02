#### User Defined Variables ####
onedrive_path = "../../../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project (1)/Database/"

###### Vector of source Excel files ######
excel_files <- 
  c(
    "Extractions_sheet.xlsx",
    "Library_Contents_sheet.xlsx",
    "Lot_sheet.xlsx",
    "Sequence_info_sheet.xlsx",
    "Individual_sheet.xlsx",
    "Library_Info_sheet.xlsx",
    "Sequence_info_sheet.xlsx",
    "Shipment_sheet.xlsx",
    "Species_sheet.xlsx"
  )

###### Corresponding destination directories (one level up from the working dir) ######
dest_dirs <- 
  c(
    "../db_files/dna_extractions_sheets",
    "../other_sheets",
    "../db_files/lots_sheets",
    "../other_sheets",
    "../db_files/individuals_sheets",
    "../other_sheets",
    "../db_files/sequence_info_sheets",
    "../db_files/shipments_sheets",
    "../db_files/species_sheets"
  )

#### INITIALIZE ####
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#### PACKAGES ####

cran_packages <- 
  c(
    "tidyverse", 
    # "BiocManager", 
    "janitor", 
    # "devtools"
    # "phangorn", 
    "readxl" 
    # "ape",
    # "tinytex", 
    # "igraph", 
    # "ips", 
    # "seqinr", 
    # "ggtext", 
    # "bios2mds", 
    # "rgl",
    # "RCurl", 
    # "ggrepel", 
    # "haplotypes", 
    # "tidytree", 
    # "ggimage"
  )

special_packages <- list(
  # list(pkg = "Biostrings",    source = "Bioc",   repo = "Biostrings",               install_options = list()),
  # list(pkg = "seqLogo",       source = "Bioc",   repo = "seqLogo",                  install_options = list()),
  # list(pkg = "microRNA",      source = "Bioc",   repo = "microRNA",                 install_options = list()),
  # list(pkg = "ggtree",        source = "Bioc",   repo = "ggtree",                   install_options = list()),
  # list(pkg = "msa",           source = "Bioc",   repo = "msa",                      install_options = list()),
  # list(pkg = "ggimage",       source = "GitHub", repo = "GuangchuangYu/ggimage",    install_options = list()),
  # list(pkg = "R4RNA",         source = "Bioc",   repo = "R4RNA",                    install_options = list()),
  # list(pkg = "ggmsa",         source = "GitHub", repo = "YuLab-SMU/ggmsa",           install_options = list()),
  # list(pkg = "treedataverse", source = "Bioc",   repo = "YuLab-SMU/treedataverse",   install_options = list()),
  # list(pkg = "usedist",       source = "GitHub", repo = "kylebittinger/usedist",     install_options = list()),
  # list(pkg = "rMSA",          source = "GitHub", repo = "mhahsler/rMSA",              install_options = list())
)

setRepositories(ind=1:2)

# A helper function that:
# 1. Attempts to load a package (quietly, without startup messages).
# 2. If the package is not available, it installs the package using the
#    specified source (CRAN, Bioc, or GitHub) and installation options.
# 3. Finally, it attempts to load the package again, printing a clear message
#    if the package still fails to load.
load_install_pkg <- 
  function(pkg, source = "CRAN", repo = NULL, install_options = list()) {
    if (!suppressPackageStartupMessages(require(pkg, character.only = TRUE))) {
      message("Package '", pkg, "' not found. Attempting installation from ", source, " ...")
      tryCatch({
        if (source == "CRAN") {
          install.packages(pkg, Ncpus = parallel::detectCores() - 1)
        } else if (source == "Bioc") {
          do.call(BiocManager::install, c(list(pkg), install_options))
        } else if (source == "GitHub") {
          if (is.null(repo)) {
            stop("For GitHub installation, 'repo' must be specified for package '", pkg, "'.")
          }
          do.call(devtools::install_github, c(list(repo), install_options))
        } else {
          stop("Unknown installation source '", source, "' for package '", pkg, "'.")
        }
      }, error = function(e) {
        message("Installation of package '", pkg, "' failed: ", e$message)
      })
      
      if (!suppressPackageStartupMessages(require(pkg, character.only = TRUE))) {
        message("Failed to load package '", pkg, "' even after installation. Please check the installation or try again later.")
      } else {
        message("Successfully loaded package '", pkg, "'.")
      }
    } else {
      message("Package '", pkg, "' loaded successfully.")
    }
  }

# Loop through and process each CRAN package.
for (pkg in cran_packages) {
  load_install_pkg(pkg = pkg, source = "CRAN")
}

# Loop through and process each special package.
for (pkg_info in special_packages) {
  load_install_pkg(
    pkg = pkg_info$pkg,
    source = pkg_info$source,
    repo = pkg_info$repo,
    install_options = pkg_info$install_options
  )
}

rm(special_packages, cran_packages, pkg, pkg_info)

#### convert files from xlsx to tsv and save to repo ####

purrr::walk2(excel_files, dest_dirs, function(fname, ddir) {
  # Construct full paths
  in_path  <- file.path(onedrive_path, fname)
  out_path <- file.path(ddir, str_replace(fname, "\\.xlsx$", ".tsv"))
  
  # Create destination directory if it doesn't exist
  if (!dir.exists(ddir)) dir.create(ddir, recursive = TRUE)
  
  # Read the first sheet of the workbook and write as TSV
  read_excel(in_path) %>%
    strip_newlines() %>%
    write_tsv(out_path, eol = "\n")
  
  message("✅ Wrote ", out_path)
})

