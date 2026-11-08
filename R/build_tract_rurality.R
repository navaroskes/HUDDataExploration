# build_tract_rurality.R
# Builds a national census-tract table with three rural/urban definitions:
#   1. Metro / nonmetro status  (county level, from RUCC 2023 / 2023 OMB metro delineations)
#   2. Rural-Urban Continuum Code (RUCC 2023, county level, codes 1-9)
#   3. Rural-Urban Commuting Area code (RUCA 2020, tract level, primary 1-10 + secondary)
# Output: Data/tract_rurality.csv  (one row per 2020 census tract)
# Source: USDA Economic Research Service
# Open HUD.Rproj before running, so here() points to the HUD folder.

# install.packages(c("tidyverse", "here"))   # run once if needed
library(tidyverse)
library(here)

raw_dir  <- here("Data", "raw")
out_file <- here("Data", "tract_rurality.csv")
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

# ---- 1. Download source files (skips if already downloaded) ----
ruca_url  <- "https://www.ers.usda.gov/media/5443/2020-rural-urban-commuting-area-codes-census-tracts.csv?v=54570"
rucc_url  <- "https://ers.usda.gov/media/5768/2023-rural-urban-continuum-codes.csv?v=69197"
ruca_file <- file.path(raw_dir, "ruca_2020_tracts.csv")
rucc_file <- file.path(raw_dir, "rucc_2023_counties.csv")

if (!file.exists(ruca_file)) download.file(ruca_url, ruca_file, mode = "wb")
if (!file.exists(rucc_file)) download.file(rucc_url, rucc_file, mode = "wb")

# ---- 2. RUCA (tract level) ----
# Read everything as text so GEOIDs keep their leading zeros
ruca <- read_csv(ruca_file, col_types = cols(.default = col_character()),
                 locale = locale(encoding = "latin1")) %>%
  transmute(
    tract_geoid         = TractFIPS23,   # matches ACS 2022+ (incl. new Connecticut codes)
    tract_geoid_2020    = TractFIPS20,   # original 2020 Census tract ID
    county_geoid        = CountyFIPS23,
    state_fips          = StateFIPS20,
    state_name          = StateName20,
    county_name         = CountyName23,
    tract_name          = TractName20,
    ruca_primary        = as.numeric(PrimaryRUCA),
    ruca_primary_desc   = PrimaryRUCADescription,
    ruca_secondary      = as.numeric(SecondaryRUCA),
    ruca_secondary_desc = SecondaryRUCADescription
  )

# ---- 3. RUCC (county level) ----
# This file is "long" (one row per county per attribute), so reshape to one row per county
rucc <- read_csv(rucc_file, col_types = cols(.default = col_character()),
                 locale = locale(encoding = "latin1")) %>%
  filter(Attribute %in% c("RUCC_2023", "Description")) %>%
  pivot_wider(id_cols = FIPS, names_from = Attribute, values_from = Value) %>%
  transmute(
    county_geoid     = FIPS,
    rucc_2023        = as.integer(RUCC_2023),
    rucc_description = Description,
    metro_nonmetro   = if_else(rucc_2023 <= 3, "Metro", "Nonmetro")   # RUCC 1-3 = metro
  )

# ---- 4. Join: every tract gets its county's RUCC and metro status ----
tract_rurality <- ruca %>%
  left_join(rucc, by = "county_geoid") %>%
  relocate(metro_nonmetro, rucc_2023, rucc_description, .after = tract_name)

# ---- 5. Look at it (before saving) ----
View(tract_rurality)                                   # opens as a spreadsheet tab
glimpse(tract_rurality)                                # column names + types

# Checks
nrow(tract_rurality)                                   # number of tracts
sum(is.na(tract_rurality$rucc_2023))                   # tracts with no RUCC match (should be ~0)
count(tract_rurality, metro_nonmetro)
count(tract_rurality, ruca_primary, ruca_primary_desc)
tract_rurality %>% filter(is.na(rucc_2023)) %>% count(state_name)   # where any non-matches are

# ---- 6. Save (uncomment and run once you're happy with it) ----
# write_csv(tract_rurality, out_file)