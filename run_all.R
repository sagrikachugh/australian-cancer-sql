# Run the complete reproducible pipeline: clean, load, QA, test and render three
# parameterised reports. Run from the repository root with Rscript run_all.R.

required_packages <- c(
  "DBI", "duckdb", "readxl", "readr", "dplyr", "ggplot2", "testthat",
  "withr", "knitr", "scales"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing R packages: ", paste(missing_packages, collapse = ", "),
    ". Install them before running the pipeline.", call. = FALSE
  )
}
if (!nzchar(Sys.which("quarto"))) {
  stop("Quarto CLI is not available on PATH.", call. = FALSE)
}

source("R/01_clean.R")
source("R/02_load_duckdb.R")
source("R/03_run_qa.R")

testthat::test_dir("tests", reporter = "summary", stop_on_failure = TRUE)

report_codes <- c("breast_cancer", "colorectal_cancer", "lung_cancer")
available <- readr::read_csv("data/processed/cancer_type.csv", show_col_types = FALSE)$cancer_code
missing_codes <- setdiff(report_codes, available)
if (length(missing_codes) > 0L) {
  stop("Report cancer codes not found: ", paste(missing_codes, collapse = ", "), call. = FALSE)
}

dir.create("output", showWarnings = FALSE)
render_report <- function(cancer_code) {
  output_name <- paste0("cancer_profile_", cancer_code, ".html")
  original_wd <- getwd()
  setwd("reports")
  on.exit(setwd(original_wd), add = TRUE)

  status <- system2(
    "quarto",
    c(
      "render", "cancer_profile.qmd",
      "--output", output_name,
      "-P", paste0("cancer_code:", cancer_code)
    )
  )
  if (!identical(status, 0L)) stop("Quarto render failed for ", cancer_code, call. = FALSE)
  rendered <- file.path(getwd(), output_name)
  destination <- file.path(original_wd, "output", output_name)
  if (file.exists(destination)) unlink(destination)
  if (!file.rename(rendered, destination)) stop("Could not move report to ", destination, call. = FALSE)
  message("Rendered ", file.path("output", output_name))
}

for (cancer_code in report_codes) {
  render_report(cancer_code)
}

message("Pipeline complete: clean -> load -> QA -> tests -> 3 reports.")
