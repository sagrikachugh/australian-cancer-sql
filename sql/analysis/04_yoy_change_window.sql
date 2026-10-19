-- Calculate year-on-year change in published ASR for one cancer using LAG().
-- Rows retain their annual grain, unlike a GROUP BY aggregation.

WITH lagged AS (
  SELECT
    year,
    sex,
    asr,
    is_projection,
    LAG(asr) OVER (PARTITION BY cancer_code, sex ORDER BY year) AS previous_asr
  FROM incidence
  WHERE cancer_code = ?
    AND age_group = 'All ages'
)
SELECT
  year,
  sex,
  asr,
  previous_asr,
  asr - previous_asr AS absolute_change,
  100.0 * (asr - previous_asr) / NULLIF(previous_asr, 0) AS percentage_change,
  is_projection
FROM lagged
ORDER BY sex, year;

