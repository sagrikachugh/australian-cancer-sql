-- Rank cancers within each sex in the latest observed incidence year.
-- RANK preserves ties, so more than five rows per sex are possible at the boundary.

WITH latest_observed AS (
  SELECT MAX(year) AS year
  FROM incidence
  WHERE is_projection = FALSE
),
ranked AS (
  SELECT
    i.year,
    i.sex,
    i.cancer_code,
    c.cancer_name,
    i.count,
    RANK() OVER (PARTITION BY i.sex ORDER BY i.count DESC) AS incidence_rank
  FROM incidence AS i
  INNER JOIN cancer_type AS c USING (cancer_code)
  INNER JOIN latest_observed AS latest ON i.year = latest.year
  WHERE i.age_group = 'All ages'
    AND i.is_projection = FALSE
    AND i.cancer_code <> 'all_cancers_combined'
)
SELECT year, sex, cancer_code, cancer_name, count, incidence_rank
FROM ranked
WHERE incidence_rank <= 5
ORDER BY sex, incidence_rank, cancer_name;

