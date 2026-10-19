-- Show the distribution of cases across published age bands for one cancer.
-- Percentages use known-age bands; AIHW All ages totals can also include unknown age.

WITH latest_observed AS (
  SELECT MAX(year) AS year
  FROM incidence
  WHERE cancer_code = ?
    AND sex = 'Persons'
    AND age_group <> 'All ages'
    AND is_projection = FALSE
),
profile AS (
  SELECT
    i.year,
    i.cancer_code,
    i.age_group,
    i.count,
    SUM(i.count) OVER (PARTITION BY i.cancer_code, i.year, i.sex) AS known_age_count
  FROM incidence AS i
  INNER JOIN latest_observed AS latest ON i.year = latest.year
  WHERE i.cancer_code = ?
    AND i.sex = 'Persons'
    AND i.age_group <> 'All ages'
    AND i.is_projection = FALSE
)
SELECT
  year,
  cancer_code,
  age_group,
  count,
  known_age_count,
  100.0 * count / NULLIF(known_age_count, 0) AS percentage_of_known_age_cases
FROM profile
ORDER BY
  CASE WHEN age_group = '90+' THEN 90 ELSE CAST(SPLIT_PART(age_group, '-', 1) AS INTEGER) END;

