# ---- Map: U.S. counties by metro / nonmetro status ----
library(tidyverse)
library(tigris)
library(sf)
library(here)
options(tigris_use_cache = TRUE)

# 1. One row per county from the dataset we built
county_class <- tract_rurality %>%
  distinct(county_geoid, metro_nonmetro, rucc_2023)

# 2. Simplified county boundaries; shift_geometry() moves AK, HI, PR below the lower 48
us_counties <- counties(cb = TRUE, resolution = "20m", year = 2023) %>%
  shift_geometry()

# 3. Join and map
us_counties %>%
  left_join(county_class, by = c("GEOID" = "county_geoid")) %>%
  ggplot() +
  geom_sf(aes(fill = metro_nonmetro), color = "white", linewidth = 0.05) +
  scale_fill_manual(
    values   = c("Metro" = "#1f4e79", "Nonmetro" = "#a8c66c"),
    na.value = "grey85"
  ) +
  labs(
    title    = "U.S. counties by metro status",
    subtitle = "Metro = Rural-Urban Continuum Codes 1-3 (2023 OMB delineation)",
    fill     = NULL,
    caption  = "Source: USDA ERS Rural-Urban Continuum Codes 2023"
  ) +
  theme_void() +
  theme(legend.position = "bottom")