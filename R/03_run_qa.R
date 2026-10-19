# Execute every SQL QA check, write an auditable summary and fail the pipeline
# when any check returns problem rows.

source("R/utils.R")

db_path <- "data/cancer.duckdb"
if (!file.exists(db_path)) stop("Database not found: ", db_path, call. = FALSE)
dir.create("output", showWarnings = FALSE)

tables_by_check <- list(
  qa_duplicate_keys = c("incidence", "mortality"),
  qa_null_values = c("incidence", "mortality"),
  qa_missing_years = c("incidence", "mortality"),
  qa_negative_or_implausible = c("incidence", "mortality"),
  qa_orphan_cancer_types = c("incidence", "mortality")
)

run_qa <- function() {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  qa_files <- sort(list.files("sql/qa", pattern = "\\.sql$", full.names = TRUE))
  if (length(qa_files) == 0L) stop("No QA SQL files found.", call. = FALSE)

  details <- list()
  summary_rows <- list()
  for (path in qa_files) {
    check <- tools::file_path_sans_ext(basename(path))
    result <- run_sql(con, path)
    details[[check]] <- result
    expected_tables <- tables_by_check[[check]]
    if (is.null(expected_tables)) expected_tables <- "both"

    for (table_name in expected_tables) {
      n_problem_rows <- if ("source_table" %in% names(result)) {
        sum(result$source_table == table_name, na.rm = TRUE)
      } else {
        nrow(result)
      }
      summary_rows[[length(summary_rows) + 1L]] <- data.frame(
        check = check,
        table = table_name,
        n_problem_rows = n_problem_rows,
        status = if (n_problem_rows == 0L) "PASS" else "FAIL"
      )
    }
  }

  summary <- dplyr::bind_rows(summary_rows)
  readr::write_csv(summary, "output/qa_report.csv")
  print(summary)

  failures <- dplyr::filter(summary, .data$status == "FAIL")
  if (nrow(failures) > 0L) {
    stop("QA failed. Inspect output/qa_report.csv and rerun the individual SQL checks.", call. = FALSE)
  }
  message("All ", nrow(summary), " table-level QA checks passed.")
  invisible(summary)
}

run_qa()
