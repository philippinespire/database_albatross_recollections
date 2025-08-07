# database2.0: Albatross Recollections

---

![](database_erd.png)

---

## Basic Structure

* every data file is tidy
* each entity (table) in the databased is represented by a directory
  * The directory should be populated by one or more tsv files (no excel)
  * These files should be concatenatable using `bind_rows()`, i.e. they should have the same columns
* each entity (table) should follow a relational database structure
  * entities (tables) should be assembled in R as tibbles (dataframes)
  * `dm` should be used to create the database object
 
  * 

## How to use this repo
1. Clone this repository
2. Open `database_albatross_recollections.Rproj` in RStudio
3. If this is the first time cloning the repo run `setup_project()` to install needed packages and restart R (Session → Restart R or Ctrl+Shift+F10)
4. Open and run `scripts/assemble_db.R` or use `open_main_script()` to open [`scripts/assemble_db.R`](scripts/assemble_db.R) to interactively create the database as a `dm` object

## How to edit the database
After cloning the repo locally:
* Add a new table to the relevant subdirectory in `db_files`. Be sure to use the exact same column names and cell formatting as the existing table in that directory. 
* Use an informative name of the format INITIALS-YEAR-MONTH-DAY-DESC.tsv, where you're using your initials, the 4-digit year, the 2-digit month, and a short description without any punctuation or spaces.
* The database creation script reads in and row-binds all files in a given directory to create the relevant database tables.
* Check the [`scripts/assemble_db.R`](scripts/assemble_db.R) runs correctly with your new file
* Push back to GitHub
