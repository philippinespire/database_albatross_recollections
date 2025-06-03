# Scripts

---

## Assemble Database


---

#### `wrangle_db_files.R`

Primarily sourced by other scripts `assemble_db.R` and `troubleshoot_database_key_identification.R`. Reads in and concatentates database files (moved and reformatted from Onedrive with `transfer_sheets_to_repo.R`). Output is a named list of dataframes suitable for use by the [`dm`](https://dm.cynkra.com/) package. 

---

#### `assemble_db.R`:
This function makes the database.

---

## Custom Functions
Source the functions.R script to load these.

#### `install_and_load_packages()`

function to install packages if they don't exist

* Run with defaults (tidyverse, janitor, readxl):
	```r
	install_and_load()
	```
	
* Add nondefault cran packages as well as Bioc and GitHub packages:

	```R
	extras <- list(
	  list(pkg = "Biostrings", source = "Bioc",   repo = "Biostrings"),
	  list(pkg = "ggimage",    source = "GitHub", repo = "GuangchuangYu/ggimage",
		   install_options = list(build_vignettes = FALSE))
	)

	install_and_load(
	  cran_packages    = 
		c(
			"tidyverse", 
			"janitor", 
			"readxl", 
			"patchwork"
		),
	  special_packages = extras
	)

	```

---

## Helper Scripts

---

#### `transfer_sheets_to_repo.R`

transfers files from the Carpenter Lab Philippines Database dir to the GitHub Repo

* the path to the OneDrive dir `onedrive_path` must be set separately for each user/computer who runs this script.

	* Must be able to sync OneDrive files to local computer
	
---

## Troubleshooting Scripts

#### `find_lots_and_fieldCollections.R`
* the path to the OneDrive dir `onedrive_path` must be set separately for each user/computer who runs this script.

	* Must be able to sync OneDrive files to local computer

Script to be used interactively to read all excel files found in `Philippines_PIRE_project/Field Collections` to identify any which contain the column `Lot_ID`. Checks to see if any of these Lot_IDs are missing in the `Philippines_PIRE_project/Database/Lot_sheet.xlsx`

---

#### `troubleshoot_database_key_identification.R`

Script used to identify problems with primary and foreign keys to be used in joining the database together.

---

## Scripts to Fix files

---

