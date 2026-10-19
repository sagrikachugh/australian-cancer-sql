# Data

The pipeline uses two official Australian Institute of Health and Welfare (AIHW) workbooks from *Cancer Data in Australia 2025*, released October 2025 and downloaded on 19 October 2026:

- `CDiA-2025-Book-1a-Cancer-incidence-age-standardised-rates-5-year-age-groups.xlsx`, sheet `Table S1a.1` (Australian Cancer Database incidence)
- `CDiA-2025-Book-2a-Cancer-mortality-and-age-standardised-rates-by-age-5-year-groups.xlsx`, sheet `Table S2a.1` (National Mortality Database mortality)

Source: [AIHW Cancer data in Australia — Data](https://www.aihw.gov.au/reports/cancer/cancer-data-in-australia/data).

Raw workbooks are downloaded to `data/raw/` when absent and are excluded from Git. Clean CSVs in `data/processed/` are also generated artifacts. `source_metadata.csv` records the exact URLs, local filenames, sheets and download date for each run.

The cleaned data retain national results from 2000 onward for Males, Females and Persons. AIHW projections are retained but explicitly flagged. The pipeline uses the published 2001 Australian Standard Population ASR and does not calculate its own standardisation. The `published_rate` field is age-specific for age bands and crude for the All ages row.

Some same-named cancer groups use different ICD-10 definitions in the incidence and NMD mortality workbooks. The cancer dimension preserves the incidence definition in `icd10_codes` and the mortality definition in `mortality_icd10_codes` rather than merging the labels.
