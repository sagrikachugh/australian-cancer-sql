# Rebuild the embedded DuckDB database from the validated processed CSV files.

source("R/utils.R")

required <- file.path("data/processed", c("cancer_type.csv", "incidence.csv", "mortality.csv"))
missing <- required[!file.exists(required)]
if (length(missing) > 0L) {
  stop("Missing processed files: ", paste(missing, collapse = ", "), call. = FALSE)
}

load_database <- function() {
  db_path <- "data/cancer.duckdb"
  if (file.exists(db_path)) unlink(db_path)
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  run_sql_script(con, "sql/schema.sql")

  cancer_type <- readr::read_csv(required[[1]], show_col_types = FALSE)
  incidence <- readr::read_csv(required[[2]], show_col_types = FALSE)
  mortality <- readr::read_csv(required[[3]], show_col_types = FALSE)

  DBI::dbAppendTable(con, "cancer_type", cancer_type)
  DBI::dbAppendTable(con, "incidence", incidence)
  DBI::dbAppendTable(con, "mortality", mortality)

  message(
    "Loaded DuckDB: ", nrow(cancer_type), " cancer types, ", nrow(incidence),
    " incidence rows, ", nrow(mortality), " mortality rows."
  )
}

load_database()
