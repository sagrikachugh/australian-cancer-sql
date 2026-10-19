# Shared helpers for reading SQL files, executing parameterised queries and
# locating project files consistently from scripts, tests and Quarto.

read_sql <- function(path) {
  if (!file.exists(path)) {
    stop("SQL file not found: ", path, call. = FALSE)
  }
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

run_sql <- function(con, path, params = list()) {
  sql <- read_sql(path)
  if (length(params) == 0L) {
    DBI::dbGetQuery(con, sql)
  } else {
    DBI::dbGetQuery(con, sql, params = unname(params))
  }
}

run_sql_script <- function(con, path) {
  sql <- read_sql(path)
  statements <- trimws(strsplit(sql, ";", fixed = TRUE)[[1]])
  statements <- statements[nzchar(statements)]
  invisible(lapply(statements, function(statement) DBI::dbExecute(con, statement)))
}

slugify <- function(x) {
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("(^_+|_+$)", "", x)
}

assert_columns <- function(data, expected, source) {
  missing <- setdiff(expected, names(data))
  if (length(missing) > 0L) {
    stop(source, " is missing expected columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

