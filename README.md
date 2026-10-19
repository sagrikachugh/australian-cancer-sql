# Australian cancer statistics with SQL

I built this project to practise a complete SQL analysis workflow using public Australian cancer data. It loads national incidence and mortality statistics into DuckDB, answers six analytical questions in SQL, checks data quality, and renders Quarto reports for breast, colorectal and lung cancer. The data are national rather than NSW-specific.

## Run

Requirements are R 4.3 or later, Quarto CLI, and the R packages listed in `run_all.R`. Then run:

```bash
Rscript run_all.R
```

If the raw workbooks are missing, the cleaning script downloads the official files. If download fails it stops and asks for the real files; it never creates synthetic data. The command cleans and validates the workbooks, rebuilds DuckDB, runs SQL QA, runs tests, and renders three HTML reports in `output/`.

Example: [breast cancer profile](https://sagrikachugh.github.io/nsw-cancer-sql/output/cancer_profile_breast_cancer.html)

## SQL analysis

| File | Question | SQL concepts |
|---|---|---|
| `01_top_cancers_latest_year.sql` | Which cancers have the most cases in the latest observed year? | CTE, aggregation filter, join, ordering |
| `02_incidence_trend.sql` | How do incidence and mortality change for one cancer? | Parameters, `UNION ALL`, filtering |
| `03_mortality_to_incidence.sql` | What is the deaths-to-new-cases ratio in the latest common observed year for identically defined cancer groups? | CTE, inner join, `NULLIF` |
| `04_yoy_change_window.sql` | How does ASR change year to year? | `LAG`, `PARTITION BY` |
| `05_rank_by_sex.sql` | What are the five highest-count cancers within each sex? | `RANK`, window partition |
| `06_age_profile.sql` | What share of known-age cases falls in each age group? | `SUM() OVER`, parameter, CTE |

The queries use `?` placeholders bound through DBI. Latest-year rankings use observed data only; projected years remain available and are labelled in trend reports.

## Data quality

Five SQL checks return problem rows for duplicate keys, NULL keys/counts, internal missing years, negative or implausible values, and orphan cancer codes. `R/03_run_qa.R` writes `output/qa_report.csv` and stops if any result is returned. Missing-year expectations use each cancer/sex/age series' own first and last year because AIHW documents legitimate late-starting series and cancers without projections.

The current end-to-end run passes all table-level checks. Tests also verify the six analysis-query output contracts and a plausible incidence year range.

## Source and limitations

Source: Australian Institute of Health and Welfare, *Cancer Data in Australia 2025*, [data downloads](https://www.aihw.gov.au/reports/cancer/cancer-data-in-australia/data). Incidence comes from the Australian Cancer Database; mortality comes from the National Mortality Database.

These are aggregate national statistics, not record-level or NSW-specific data. Incidence is observed through 2021 and projected for 2022–2025; NMD mortality is observed through 2023 and projected for 2024–2025. Published values can change between AIHW releases. Age-standardised rates are used as supplied by AIHW. The age profile divides by the sum of known-age bands, while AIHW's all-ages count may include unknown age.

Seven same-named cancer groups have different ICD-10 definitions across the two source workbooks. Both definitions are retained in the dimension, reports disclose the difference, and the mortality-to-incidence query excludes those groups rather than presenting a misleading ratio.
