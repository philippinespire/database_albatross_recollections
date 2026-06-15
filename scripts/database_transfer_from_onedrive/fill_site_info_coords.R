the_db <- pire_database()

# A tibble: 4 × 11
# lot_id           site_id match_id collection_site latitude longitude barangay local_government_unit province region island_group 
# 1 Jol-2021-04_02   Jol     Jolo     Jolo_Island         6.06      121. NA       NA                    Sulu     BARMM  Mindanao    
# 2 Cam-2019-011_015 Pas     RagR     Pasacao            NA          NA  NA       NA                    NA       NA     NA          
# 3 Kal-2019-002_002 Kal     NA       Kalibo             NA          NA  NA       NA                    NA       NA     NA          
# 4 Jol-2021-01_03   Jol     Jolo     Jolo                6.06      121. NA       NA                    Sulu     BARMM  Mindanao    
# 5 Bat-2018-002_002 Nas     Nasu     Nasugbu               NA        NA NA       Nasugbu               Batangas CALABARZON Luzon

library(geosphere)

geo_cols <- c(
    "local_government_unit",
    "province",
    "region",
    "island_group"
)

fill_from_nearest <- function(df, max_distance_m = Inf) {
    
    df <- df %>%
        mutate(row_id_tmp = row_number())
    
    donors <- df %>%
        filter(
            !is.na(latitude),
            !is.na(longitude),
            if_all(all_of(geo_cols), ~ !is.na(.x))
        )
    
    df %>%
        rowwise() %>%
        mutate(
            donor_index = {
                needs_fill <- any(is.na(c_across(all_of(geo_cols))))
                has_coords <- !is.na(latitude) && !is.na(longitude)
                
                if (needs_fill && has_coords && nrow(donors) > 0) {
                    
                    dists <- geosphere::distHaversine(
                        c(longitude, latitude),
                        donors %>% select(longitude, latitude)
                    )
                    
                    # only exclude the actual same original row
                    dists[donors$row_id_tmp == row_id_tmp] <- Inf
                    
                    min_dist <- min(dists, na.rm = TRUE)
                    
                    if (is.infinite(min_dist) || min_dist > max_distance_m) {
                        NA_integer_
                    } else {
                        which.min(dists)
                    }
                    
                } else {
                    NA_integer_
                }
            },
            donor_distance_m = ifelse(
                !is.na(donor_index),
                geosphere::distHaversine(
                    c(longitude, latitude),
                    c(donors$longitude[donor_index], donors$latitude[donor_index])
                ),
                NA_real_
            ),
            donor_lot_id = ifelse(
                !is.na(donor_index),
                donors$lot_id[donor_index],
                NA_character_
            )
        ) %>%
        ungroup() %>%
        mutate(
            across(
                all_of(geo_cols),
                ~ ifelse(
                    is.na(.x) & !is.na(donor_index),
                    donors[[cur_column()]][donor_index],
                    .x
                )
            )
        ) %>%
        select(-row_id_tmp, -donor_index)
}


pull_tbl(the_db, 'sampling_sites_sheets') %>%
    filter(site_id %in% c('Jol', 'Pas', 'Kal', 'Nas')) %>%
    select(-sampling_sites_sheetsfile_path, -notes:-correction_date) %>%
    group_by(site_id) %>%
    group_modify(~ fill_from_nearest(.x, max_distance_m = 10000)) %>%
    ungroup() %>%
    filter(lot_id %in% c('Jol-2021-04_02', 'Cam-2019-011_015',
                         'Kal-2019-002_002', 'Jol-2021-01_03',
                         'Bat-2018-002_002')) %>%
    select(local_government_unit:donor_lot_id)


pull_tbl(the_db, 'sampling_sites_sheets') %>%
    filter(site_id %in% c('Nas')) %>%
    select(-sampling_sites_sheetsfile_path, -notes:-correction_date) %>%
    # filter(lot_id != 'Bat-2018-003_003') %>%
    group_by(site_id) %>%
    group_modify(~ fill_from_nearest(.x, max_distance_m = Inf)) %>%
    ungroup()




# Location information filled in based on nearest lot (120814) with information which was 0 m away. JDS 5.15.2026



pull_tbl(the_db, 'sampling_sites_sheets') %>%
    filter(site_id %in% c('Pas')) %>%
    select(-sampling_sites_sheetsfile_path, -notes:-correction_date) %>%
    # filter(lot_id != 'Bat-2018-003_003') %>%
    group_by(site_id) %>%
    group_modify(~ fill_from_nearest(.x, max_distance_m = Inf)) %>%
    ungroup() 


pull_tbl(the_db, 'sampling_sites_sheets') %>%
    filter(site_id %in% c('Kal')) %>%
    select(-sampling_sites_sheetsfile_path, -notes:-correction_date) %>%
    # filter(lot_id != 'Bat-2018-003_003') %>%
    group_by(site_id) %>%
    group_modify(~ fill_from_nearest(.x, max_distance_m = Inf)) %>%
    ungroup() 


pull_tbl(the_db, 'sampling_sites_sheets') %>%
    filter(str_detect(collection_site, 'Kal')) %>%
    pull(lot_id) %>%
    str_c(collapse = ', ')


pull_tbl(the_db, 'sampling_sites_sheets') %>%
    filter(str_detect(local_government_unit, 'Aklan'))

Kalibo, Aklan, Philippines

pull_tbl(the_db, 'sampling_sites_sheets') %>%
    filter(str_detect(collection_site, 'Kalibo'))


pull_tbl(the_db, 'sampling_sites_sheets') %>%
   filter(str_detect(region, 'Visayas')) %>%
    count(province, region, island_group)
