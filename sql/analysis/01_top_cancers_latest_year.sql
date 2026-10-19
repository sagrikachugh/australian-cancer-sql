-- Find the ten largest cancer incidence counts in the latest observed year.
-- The combined total is excluded because it is not an individual cancer.

WITH latest_observed AS (
  SELECT MAX(year) AS year
  FROM incidence
  WHERE is_projection = FALSE
),
ranked AS (
  SELECT
    i.year,
    i.cancer_code,
    c.cancer_name,
    i.count,
    i.asr
  FROM incidence AS i
  INNER JOIN cancer_type AS c USING (cancer_code)
  INNER JOIN latest_observed AS latest ON i.year = latest.year
  WHERE i.sex = 'Persons'
    AND i.age_group = 'All ages'
    AND i.is_projection = FALSE
    AND i.cancer_code <> 'all_cancers_combined'
)
SELECT year, cancer_code, cancer_name, count, asr
FROM ranked
ORDER BY count DESC, cancer_name
LIMIT 10;

