library(DBI)
library(duckdb)
library(dplyr)
library(ggplot2)

source("R/utils.R")

dir.create("assets", showWarnings = FALSE)

con <- dbConnect(duckdb(), dbdir = "data/cancer.duckdb", read_only = TRUE)
withr::defer(dbDisconnect(con, shutdown = TRUE))

cancer_code <- "breast_cancer"

trend <- run_sql(
  con,
  "sql/analysis/02_incidence_trend.sql",
  list(cancer_code, cancer_code)
) |>
  filter(sex == "Persons")

age_profile <- run_sql(
  con,
  "sql/analysis/06_age_profile.sql",
  list(cancer_code, cancer_code)
)

site_theme <- theme_minimal(base_size = 13) +
  theme(
    plot.background = element_rect(fill = "#fffdf8", colour = NA),
    panel.background = element_rect(fill = "#fffdf8", colour = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(colour = "#dedbd3", linewidth = 0.35),
    plot.title = element_text(colour = "#142b2a", face = "bold", size = 17),
    plot.subtitle = element_text(colour = "#52625f", size = 10.5),
    axis.title = element_text(colour = "#52625f"),
    axis.text = element_text(colour = "#52625f"),
    legend.position = "top",
    legend.justification = "left",
    legend.title = element_blank(),
    legend.text = element_text(colour = "#52625f"),
    plot.margin = margin(18, 22, 14, 18)
  )

trend_plot <- trend |>
  ggplot(aes(year, count, colour = series, linetype = is_projection)) +
  geom_line(linewidth = 1.05) +
  scale_colour_manual(values = c("Incidence" = "#087f73", "Mortality" = "#d86b4b")) +
  scale_linetype_manual(
    values = c(`FALSE` = "solid", `TRUE` = "22"),
    labels = c("Observed", "Projected")
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title = "Incidence and mortality over time",
    subtitle = "Published counts for persons; dashed lines are AIHW projections",
    x = NULL,
    y = "People"
  ) +
  site_theme

ggsave(
  "assets/breast-cancer-trend.png",
  trend_plot,
  width = 9,
  height = 5.2,
  dpi = 180,
  bg = "#fffdf8"
)

age_plot <- ggplot(
  age_profile,
  aes(reorder(age_group, percentage_of_known_age_cases), percentage_of_known_age_cases)
) +
  geom_col(fill = "#087f73", width = 0.72) +
  coord_flip() +
  labs(
    title = "Cases by age group",
    subtitle = "Share of known-age cases in the latest observed year",
    x = "Age group",
    y = "Share of cases (%)"
  ) +
  site_theme +
  theme(legend.position = "none")

ggsave(
  "assets/breast-cancer-age-profile.png",
  age_plot,
  width = 8,
  height = 6,
  dpi = 180,
  bg = "#fffdf8"
)
