# Integration tests verify data plausibility, zero-row QA checks and the public
# column contracts of all six analysis queries.

library(testthat)
library(DBI)
library(duckdb)
project_root <- normalizePath(file.path(testthat::test_path(), ".."))
source(file.path(project_root, "R", "utils.R"))

con <- dbConnect(duckdb(), dbdir = file.path(project_root, "data", "cancer.duckdb"), read_only = TRUE)
withr::defer(dbDisconnect(con, shutdown = TRUE))

test_that("fact tables contain plausible data", {
  stats <- dbGetQuery(con, "SELECT COUNT(*) AS n, MIN(year) AS min_year, MAX(year) AS max_year FROM incidence")
  expect_gt(stats$n, 0)
  expect_gte(stats$min_year, 2000)
  expect_lte(stats$max_year, as.integer(format(Sys.Date(), "%Y")) + 5L)
})

test_that("all QA queries return zero problem rows", {
  qa_files <- sort(list.files(file.path(project_root, "sql", "qa"), pattern = "\\.sql$", full.names = TRUE))
  expect_length(qa_files, 5L)
  for (path in qa_files) expect_equal(nrow(run_sql(con, path)), 0L, info = basename(path))
})

test_that("analysis queries return their documented columns", {
  cases <- list(
    list("01_top_cancers_latest_year.sql", list(), c("year", "cancer_code", "cancer_name", "count", "asr")),
    list("02_incidence_trend.sql", list("breast_cancer", "breast_cancer"), c("series", "year", "sex", "count", "asr", "is_projection")),
    list("03_mortality_to_incidence.sql", list(), c("year", "cancer_code", "cancer_name", "incidence_count", "mortality_count", "mortality_to_incidence_ratio")),
    list("04_yoy_change_window.sql", list("breast_cancer"), c("year", "sex", "asr", "previous_asr", "absolute_change", "percentage_change", "is_projection")),
    list("05_rank_by_sex.sql", list(), c("year", "sex", "cancer_code", "cancer_name", "count", "incidence_rank")),
    list("06_age_profile.sql", list("breast_cancer", "breast_cancer"), c("year", "cancer_code", "age_group", "count", "known_age_count", "percentage_of_known_age_cases"))
  )
  for (case in cases) {
    result <- run_sql(con, file.path(project_root, "sql", "analysis", case[[1]]), case[[2]])
    expect_gt(nrow(result), 0L, label = case[[1]])
    expect_named(result, case[[3]], info = case[[1]])
  }
})
