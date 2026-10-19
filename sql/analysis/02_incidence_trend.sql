-- Return published incidence and mortality trends for one cancer code.
-- A shared shape lets the report compare both series without embedding SQL in R.

SELECT
  'Incidence' AS series,
  year,
  sex,
  count,
  asr,
  is_projection
FROM incidence
WHERE cancer_code = ?
  AND age_group = 'All ages'

UNION ALL

SELECT
  'Mortality' AS series,
  year,
  sex,
  count,
  asr,
  is_projection
FROM mortality
WHERE cancer_code = ?
  AND age_group = 'All ages'

ORDER BY series, sex, year;

