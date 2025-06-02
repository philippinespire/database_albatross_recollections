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
Run scripts/voltron_db.R to create the database as a `dm` object
