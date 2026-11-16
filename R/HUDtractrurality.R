# build_tract_hud.R
# Builds a national census-tract x quarter panel with:
#   1. The same USDA rural/urban columns as tract_rurality.csv (metro/nonmetro, RUCC 2023, RUCA 2020)
#   2. HUD Aggregated USPS Administrative Data on Address Vacancies (all columns), plus vacancy rates
# Output: Data/tract_hud_vacancy.parquet  (one row per 2020 census tract per quarter)
# Quarters: 2023-Q1 onward, the first quarters HUD reports on 2020 census tracts (matches RUCA 2020).
#   Earlier HUD quarters use 2000 tracts (to 2011-Q4) or 2010 tracts (2012-Q1 to 2022-Q4) and would need a crosswalk.
# Run build_tract_rurality.R first (this script reads Data/tract_rurality.csv).
# Open HUD.Rproj before running, so here() points to the HUD folder.

# install.packages(c("tidyverse", "here", "arrow"))   # run once if needed
library(tidyverse)
library(here)
library(arrow)

first_year <- 2023                                   # 2020 census tracts start in 2023-Q1
hud_dir    <- here("Data", "Vacancy")
out_file   <- here("Data", "tract_hud_vacancy.parquet")

# ---- 1. USDA columns (same as tract_rurality.csv) ----
tract_rurality <- read_csv(here("Data", "tract_rurality.csv"),
                           col_types = cols(.default = col_character())) %>%
  mutate(rucc_2023      = as.integer(rucc_2023),
         ruca_primary   = as.numeric(ruca_primary),
         ruca_secondary = as.numeric(ruca_secondary))

# HUD uses old Connecticut tract IDs in early 2023 and new ones later, so match on either ID column
id_lookup <- bind_rows(
  transmute(tract_rurality, hud_geoid = tract_geoid,      tract_geoid),
  transmute(tract_rurality, hud_geoid = tract_geoid_2020, tract_geoid)
) %>%
  distinct()
stopifnot(!any(duplicated(id_lookup$hud_geoid)))     # each HUD ID points to one tract

# ---- 2. HUD vacancy data (one Parquet file per quarter) ----
files     <- list.files(hud_dir, pattern = "\\.parquet$", recursive = TRUE, full.names = TRUE)
file_year <- as.integer(str_match(files, "year=(\\d{4})")[, 2])
files     <- files[file_year >= first_year]
message("Reading ", length(files), " quarters of HUD data")

hud <- map_dfr(files, read_parquet) %>%
  rename(hud_geoid = geoid_tr)

# ---- 3. Match HUD tracts to the USDA tract list ----
hud <- hud %>% left_join(id_lookup, by = "hud_geoid")

hud %>%                                              # HUD tracts with no USDA match, by quarter (should be ~0)
  group_by(year, quarter) %>%
  summarise(hud_tracts = n(), unmatched = sum(is.na(tract_geoid)), .groups = "drop") %>%
  print(n = 50)

hud <- hud %>% filter(!is.na(tract_geoid))
stopifnot(!any(duplicated(hud[, c("tract_geoid", "year", "quarter")])))   # one row per tract-quarter

# ---- 4. Vacancy rates (rates, not counts: about 1% of addresses fail to geocode each quarter) ----
safe_div <- function(a, b) if_else(b > 0, a / b, NA_real_)

hud <- hud %>%
  mutate(
    period                = paste0(year, "-", quarter),                       # e.g. "2025-Q4"
    res_vacancy_rate      = safe_div(res_vacant, res_addresses),
    bus_vacancy_rate      = safe_div(bus_vacant, bus_addresses),              # key downtown measure
    oth_vacancy_rate      = safe_div(oth_vacant, oth_addresses),
    res_nostat_rate       = safe_div(res_nostat, res_addresses),
    bus_nostat_rate       = safe_div(bus_nostat, bus_addresses),
    res_long_vacant_share = safe_div(res_vac_12_24mo + res_vac_24_36mo + res_vac_gte_36mo, res_vacant),
    bus_long_vacant_share = safe_div(bus_vac_12_24mo + bus_vac_24_36mo + bus_vac_gte_36mo, bus_vacant)
  )

# ---- 5. Join: every tract-quarter gets its USDA columns ----
tract_hud <- hud %>%
  left_join(tract_rurality, by = "tract_geoid") %>%
  select(all_of(names(tract_rurality)),                                       # USDA columns first, same order
         year, quarter, period, epoch,
         res_vacancy_rate, bus_vacancy_rate, oth_vacancy_rate,
         res_nostat_rate, bus_nostat_rate,
         res_long_vacant_share, bus_long_vacant_share,
         everything(),                                                         # then every HUD column
         hud_geoid) %>%
  arrange(tract_geoid, year, quarter)

# ---- 6. Look at it (before saving) ----
View(head(tract_hud, 1000))                          # first 1,000 rows (the full table is about 1 million rows)
glimpse(tract_hud)

# Checks
nrow(tract_hud)                                      # tract-quarters
n_distinct(tract_hud$tract_geoid)                    # tracts (about 85,000)
count(tract_hud, period)                             # rows per quarter
tract_hud %>%                                        # business vacancy by metro status, latest quarter
  filter(period == max(period)) %>%
  group_by(metro_nonmetro) %>%
  summarise(tracts = n(),
            bus_vacancy_rate_median = median(bus_vacancy_rate, na.rm = TRUE),
            res_vacancy_rate_median = median(res_vacancy_rate, na.rm = TRUE))

# ---- 7. Save (uncomment and run once you're happy with it) ----
# write_parquet(tract_hud, out_file)