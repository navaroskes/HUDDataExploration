# Notes — CORI Downtown Health Report (HUD folder)
Last updated: Nov 2, 2026. Context for picking this project back up (paste into a new Claude chat to catch up).

## The project
- CORI report on **downtown health trends across city types** (rural vs. nonrural, urban, small town, downtown).
- Original plan: HUD Aggregated USPS Administrative Data on Address Vacancies (quarterly, census-tract level, residential/business/other vacancy, vacancy duration, no-stat addresses).
- Doing all analysis in **R**; also building a **GitHub portfolio** from this work (plan: play in R first, then set up GitHub).

## HUD-USPS data: access
- Tract-level data is **restricted**: only registered governmental and nonprofit users (huduser.gov, "HUD Aggregated USPS Administrative Data On Address Vacancies").
- CORI is a nonprofit, so likely eligible. **To do: ask supervisor whether CORI already has access.** Register with CORI email if not.
- Data dictionary notes: older dictionary says 2000 tracts; HUD later moved to 2010 tracts. Pre-Q4 2007 files lack residential/business split. HUD warns USPS changes make longitudinal analysis harder. ~1% of records fail to geocode each quarter (use rates, not raw counts).
- Never upload raw HUD data to a public GitHub repo; commit code and aggregated outputs only.

## Public alternatives / complements (discussed)
- **ACS** (tidycensus): B25002 occupancy (total/occupied/vacant), B25004 vacancy by type (for rent, for sale, seasonal, other vacant). 5-year estimates; residential only; margins of error matter for small tracts. Compare non-overlapping periods (e.g. 2015-2019 vs 2020-2024).
- **LEHD LODES WAC**: jobs by workplace census block (sum to tract = first 11 digits). Good for finding downtowns via job density. R package `lehdr`.
- **ZIP/County Business Patterns**, `cori.data.qcew`: establishments/jobs.
- **Downtown Recovery project** (Univ. of Toronto School of Cities): cell-phone visit data for ~62 large-city downtowns.
- Defining downtown: no official definition. Methods = local boundary, radius around city hall, or job density. Idea: RUCA "core" tracts + highest LODES job density within each city.
- Watch-outs: tract boundaries changed in 2020 (use crosswalks like NHGIS/LTDB for long trends); Connecticut switched to planning-region county codes (2022+).

## Folder setup (CORINEW)
- Project root: `C:/Users/navar/OneDrive/Documents/CORINEW` (renamed from coripractice; old `Documents/CORI` duplicate was deleted).
- RStudio project file: `CORINEW/coripractice.Rproj` — open this so `here::here()` points to CORINEW.
- Structure: `ERC/`, `HUD/`, `Other/`, each with `Code/`, `Data/`, `Images/` (ERC also has `RMarkdown/`).
- Fed Challenge files were copied to `OneDrive/Documents/FED/from_coripractice/`; originals still sit in `CORINEW/Code` and `CORINEW/Images` (leftovers, to clean up later). Empty `CORINEW/Data` and `CORINEW/RMarkdown` can also be removed.
- Careful when saving new scripts: RStudio's Save dialog defaults to the last folder used (mapbymetrostatus.R landed in CORINEW/Code by mistake and was moved).
- Use `here("HUD", "Data")`, `here("HUD", "Images")` instead of full C:/ paths (works on any computer / GitHub).

## HUD scripts (HUD/Code)
- `firsttimeACSpractice.R` — first tidycensus practice: Chittenden County, VT tract vacancy (B25002), bar chart. Census API key is installed (don't commit a real key to GitHub).
- `build_tract_rurality.R` — builds the national tract classification dataset (below). Downloads USDA files to `HUD/Data/raw/`, reads them with latin1 encoding (fixes "invalid multibyte string" error from names like Doña Ana), shows the data with View() before saving; `write_csv` line is commented out until you choose to save.
- `mapbymetrostatus.R` — U.S. county map by metro/nonmetro (tigris `counties(cb = TRUE, resolution = "20m")` + `shift_geometry()`; needed `install.packages("lwgeom")`).

## tract_rurality dataset (the key reusable dataset)
- One row per 2020 census tract nationwide (~85k). Saved to `HUD/Data/tract_rurality.csv` once written.
- Columns: `tract_geoid` (11-digit; matches ACS 2022+ incl. new CT codes), `tract_geoid_2020`, `county_geoid` (5-digit; matches ERC data), state/county/tract names, `metro_nonmetro`, `rucc_2023`, `rucc_description`, `ruca_primary`, `ruca_primary_desc`, `ruca_secondary`, `ruca_secondary_desc`.
- Sources: USDA ERS 2020 RUCA codes (census tracts) + 2023 RUCC codes (counties). Metro = RUCC 1-3 (2023 OMB delineation), computed in the script.
- RUCC/metro are county-level (same for every tract in a county); RUCA varies by tract. RUCA 99 = water-only tracts (filter out).
- RUCA groups used: 1-3 Metropolitan, 4-6 Micropolitan, 7-9 Small town, 10 Rural.
- Plan: join this to any Census data by GEOID; may add more rural/urban definitions later and choose per analysis.
- Same GEOID system as Census (2020 tracts). Keep GEOIDs as text (leading zeros).

## Things looked at so far (code was pasted in chat, not yet saved as scripts)
- Chittenden County join check: all tracts Metro / RUCC 3; RUCA splits Metropolitan core vs. high commuting.
- All Vermont tracts: classifications + vacancy rate only (one housing variable).
- Hampshire County, MA: same table.
- ZIP 01062 (Florence, MA): ACS uses ZCTAs, not ZIPs; USDA also publishes a ZIP-level RUCA file. Approximate tracts for the ZIP: **25015821602** (Census Tract 8216.02, main estimate) and **25015821601** (8216.01). Approximate only (from a property listing); confirm with the Census Geocoder if needed.
- Vacancy interpretation: ACS "vacant" includes seasonal homes and units between leases (college towns); "other vacant" is the better distress signal.

## Next steps / ideas
- Save the Vermont / Hampshire / ZIP code and maps into scripts in HUD/Code.
- Map RUCC (9 categories) instead of just metro status.
- Pull LODES jobs to identify downtown tracts by job density.
- Check HUD-USPS access through CORI.
- Set up GitHub repo (code only; key and restricted data excluded).

---
## Other things from this same chat (not HUD)
- **Health psych intervention proposal** (problematic pornography use among university students): seminar with group and individual parts. Causal factors chosen: impaired self-control (impulsivity/compulsivity) and loneliness. Steps drafted: (1) group physical exercise + sharing circle (Lin et al., 2026), (2) individual counseling challenging negative social cognition (Masi et al., 2011), (3) group CBT for self-control: urge/trigger logging and limiting access (Hallberg et al., 2019; Bothe et al., 2021 Hands-off trial; Kraus et al., 2017; Lopez-Pinar et al., 2025). Other sources used: Altin et al. 2024, Camilleri et al. 2021, Svedin et al. 2023, Bocci Benucci et al. 2024, Rousseau et al. 2021, Bothe et al. 2019, Butler et al. 2018, Vescan et al. 2024, Cardoso et al. 2022, 2026 Ecuador student study (first author name still to confirm; "Vecallos"?).
