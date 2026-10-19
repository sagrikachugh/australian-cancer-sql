-- Compare deaths with new cases in the latest observed year shared by both facts.
-- NULLIF prevents division by zero and the CTE makes the shared-year rule explicit.

WITH common_year AS (
  SELECT MAX(i.year) AS year
  FROM incidence AS i
  INNER JOIN mortality AS m
    ON i.cancer_code = m.cancer_code
   AND i.year = m.year
   AND i.sex = m.sex
   AND i.age_group = m.age_group
  WHERE i.sex = 'Persons'
    AND i.age_group = 'All ages'
    AND i.is_projection = FALSE
    AND m.is_projection = FALSE
),
joined AS (
  SELECT
    i.year,
    i.cancer_code,
    c.cancer_name,
    i.count AS incidence_count,
    m.count AS mortality_count,
    CAST(m.count AS DOUBLE) / NULLIF(i.count, 0) AS mortality_to_incidence_ratio
  FROM incidence AS i
  INNER JOIN mortality AS m
    ON i.cancer_code = m.cancer_code
   AND i.year = m.year
   AND i.sex = m.sex
   AND i.age_group = m.age_group
  INNER JOIN cancer_type AS c ON i.cancer_code = c.cancer_code
  INNER JOIN common_year AS latest ON i.year = latest.year
  WHERE i.sex = 'Persons'
    AND i.age_group = 'All ages'
    AND i.is_projection = FALSE
    AND m.is_projection = FALSE
    AND i.cancer_code <> 'all_cancers_combined'
    -- Ratios are only interpretable when both workbooks use the same definition.
    AND c.icd10_codes = c.mortality_icd10_codes
)
SELECT
  year,
  cancer_code,
  cancer_name,
  incidence_count,
  mortality_count,
  mortality_to_incidence_ratio
FROM joined
ORDER BY mortality_to_incidence_ratio DESC NULLS LAST, cancer_name;
