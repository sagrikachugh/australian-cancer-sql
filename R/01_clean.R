# Download (when needed), validate and clean the two official AIHW workbooks
# into tidy CSV files without inventing or imputing suppressed values.

source("R/utils.R")

raw_dir <- "data/raw"
processed_dir <- "data/processed"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

sources <- data.frame(
  measure = c("incidence", "mortality"),
  file_name = c(
    "CDiA-2025-Book-1a-Cancer-incidence-age-standardised-rates-5-year-age-groups.xlsx",
    "CDiA-2025-Book-2a-Cancer-mortality-and-age-standardised-rates-by-age-5-year-groups.xlsx"
  ),
  sheet_name = c("Table S1a.1", "Table S2a.1"),
  url = c(
    "https://www.aihw.gov.au/getmedia/871e40d3-bab0-4cb9-b876-0152d2efc2c7/CDiA-2025-Book-1a-Cancer-incidence-age-standardised-rates-5-year-age-groups.xlsx",
    "https://www.aihw.gov.au/getmedia/c5b5798e-a812-420a-87c4-5619b6a429ab/CDiA-2025-Book-2a-Cancer-mortality-and-age-standardised-rates-by-age-5-year-groups.xlsx"
  ),
  stringsAsFactors = FALSE
)

download_source <- function(file_name, url) {
  destination <- file.path(raw_dir, file_name)
  if (file.exists(destination)) return(destination)

  message("Downloading official AIHW workbook: ", file_name)
  ok <- tryCatch({
    utils::download.file(url, destination, mode = "wb", quiet = FALSE)
    TRUE
  }, error = function(e) {
    message(conditionMessage(e))
    FALSE
  })
  if (!ok || !file.exists(destination)) {
    stop(
      "Could not download ", file_name, ". Place the official AIHW file in ",
      raw_dir, " and run again. No synthetic data will be generated.",
      call. = FALSE
    )
  }
  destination
}

clean_workbook <- function(path, sheet_name) {
  sheets <- readxl::excel_sheets(path)
  if (!sheet_name %in% sheets) {
    stop("Expected sheet '", sheet_name, "' not found in ", basename(path), call. = FALSE)
  }

  raw <- readxl::read_excel(
    path,
    sheet = sheet_name,
    skip = 4,
    col_types = "text",
    .name_repair = "unique_quiet"
  )
  if (ncol(raw) < 13L) {
    stop("Unexpected workbook structure in ", basename(path), ": fewer than 13 columns.", call. = FALSE)
  }

  names(raw)[c(1:11, 13)] <- c(
    "data_type", "cancer_name", "year", "sex", "age_group", "count",
    "published_rate", "asr", "asr_2025_population", "asr_who", "asr_segi",
    "icd10_codes"
  )

  cleaned <- raw |>
    dplyr::filter(
      .data$data_type %in% c("Actual", "Projections"),
      .data$sex %in% c("Males", "Females", "Persons")
    ) |>
    dplyr::transmute(
      cancer_name = trimws(.data$cancer_name),
      year = suppressWarnings(as.integer(.data$year)),
      sex = .data$sex,
      age_group = dplyr::if_else(.data$age_group == "All ages combined", "All ages", .data$age_group),
      count = suppressWarnings(as.integer(.data$count)),
      published_rate = suppressWarnings(as.numeric(.data$published_rate)),
      asr = suppressWarnings(as.numeric(.data$asr)),
      icd10_codes = trimws(.data$icd10_codes),
      is_projection = .data$data_type == "Projections"
    ) |>
    dplyr::filter(.data$year >= 2000L)

  if (nrow(cleaned) == 0L || anyNA(cleaned[c("cancer_name", "year", "sex", "age_group", "count")])) {
    stop("Cleaning produced no rows or NULL key/count values for ", basename(path), call. = FALSE)
  }
  cleaned
}

paths <- mapply(download_source, sources$file_name, sources$url, USE.NAMES = FALSE)
incidence <- clean_workbook(paths[[1]], sources$sheet_name[[1]])
mortality <- clean_workbook(paths[[2]], sources$sheet_name[[2]])

incidence_codes <- incidence |>
  dplyr::group_by(.data$cancer_name) |>
  dplyr::summarise(
    icd10_codes = paste(sort(unique(stats::na.omit(.data$icd10_codes))), collapse = "; "),
    .groups = "drop"
  )

mortality_codes <- mortality |>
  dplyr::group_by(.data$cancer_name) |>
  dplyr::summarise(
    mortality_icd10_codes = paste(sort(unique(stats::na.omit(.data$icd10_codes))), collapse = "; "),
    .groups = "drop"
  )

cancer_types <- dplyr::full_join(incidence_codes, mortality_codes, by = "cancer_name") |>
  dplyr::mutate(
    icd10_codes = dplyr::coalesce(.data$icd10_codes, .data$mortality_icd10_codes),
    cancer_code = slugify(.data$cancer_name)
  ) |>
  dplyr::select("cancer_code", "cancer_name", "icd10_codes", "mortality_icd10_codes")

if (anyDuplicated(cancer_types$cancer_code)) {
  duplicates <- unique(cancer_types$cancer_code[duplicated(cancer_types$cancer_code)])
  stop("Cancer-code slug collision: ", paste(duplicates, collapse = ", "), call. = FALSE)
}

add_codes <- function(data) {
  data |>
    dplyr::left_join(dplyr::select(cancer_types, "cancer_code", "cancer_name"), by = "cancer_name") |>
    dplyr::select(
      "cancer_code", "year", "sex", "age_group", "count",
      "published_rate", "asr", "is_projection"
    )
}

readr::write_csv(cancer_types, file.path(processed_dir, "cancer_type.csv"), na = "")
readr::write_csv(add_codes(incidence), file.path(processed_dir, "incidence.csv"), na = "")
readr::write_csv(add_codes(mortality), file.path(processed_dir, "mortality.csv"), na = "")

metadata <- dplyr::mutate(
  sources,
  release = "Cancer Data in Australia 2025 (October 2025)",
  downloaded_on = format(Sys.Date(), "%Y-%m-%d"),
  local_path = file.path(raw_dir, .data$file_name)
)
readr::write_csv(metadata, file.path(processed_dir, "source_metadata.csv"))

message("Cleaned ", nrow(incidence), " incidence rows and ", nrow(mortality), " mortality rows.")
