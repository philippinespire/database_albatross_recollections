here::i_am("scripts/plot_db.R")
source(here::here("scripts", "assemble_db.R"))

#### visualize db ####
erd_image <-
    pire_db %>%
    dm_draw(rankdir = "TB",
            view_type = "keys_only")

erd_image

erd_image %>%
    DiagrammeRsvg::export_svg() %>%
    charToRaw() %>%
    rsvg::rsvg_png("database_erd.png",
                   width = 7 * 125, height = 7 * 125)


# pire_db %>%
#   dm_draw(rankdir = "TB", view_type = "all")