source(here::here("scripts", "functions.R"))

#### visualize db ####
erd_image <-
    pire_database() %>%
    dm_draw(rankdir = "TB",
            view_type = "keys_only")

erd_image

erd_image %>%
    DiagrammeRsvg::export_svg() %>%
    charToRaw() %>%
    rsvg::rsvg_png(here::here("database_erd.png"),
                   width = 7 * 125, height = 7 * 125)


# pire_db %>%
#   dm_draw(rankdir = "TB", view_type = "all")