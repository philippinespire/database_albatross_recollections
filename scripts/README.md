# Scripts

---

## Assemble Database


---

---

## Custom Functions

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

#### `find_lots_and_fieldCollections.R`
* the path to the OneDrive dir `onedrive_path` must be set separately for each user/computer who runs this script.

	* Must be able to sync OneDrive files to local computer

Script to be used interactively to read all excel files found in `Philippines_PIRE_project/Field Collections` to identify any which contain the column `Lot_ID`. Checks to see if any of these Lot_IDs are missing in the `Philippines_PIRE_project/Database/Lot_sheet.xlsx`

---