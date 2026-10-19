-- Find internal year gaps within each cancer/sex/age series using an anti-join.
-- Series-specific bounds avoid falsely failing cancers that legitimately start later.

WITH incidence_bounds AS (
  SELECT cancer_code, sex, age_group, MIN(year) AS min_year, MAX(year) AS max_year
  FROM incidence
  GROUP BY cancer_code, sex, age_group
),
incidence_expected AS (
  SELECT b.cancer_code, b.sex, b.age_group, expected.year
  FROM incidence_bounds AS b
  CROSS JOIN LATERAL range(b.min_year, b.max_year + 1) AS expected(year)
),
mortality_bounds AS (
  SELECT cancer_code, sex, age_group, MIN(year) AS min_year, MAX(year) AS max_year
  FROM mortality
  GROUP BY cancer_code, sex, age_group
),
mortality_expected AS (
  SELECT b.cancer_code, b.sex, b.age_group, expected.year
  FROM mortality_bounds AS b
  CROSS JOIN LATERAL range(b.min_year, b.max_year + 1) AS expected(year)
)
SELECT 'incidence' AS source_table, e.cancer_code, e.year, e.sex, e.age_group
FROM incidence_expected AS e
LEFT JOIN incidence AS i
  ON e.cancer_code = i.cancer_code AND e.year = i.year
 AND e.sex = i.sex AND e.age_group = i.age_group
WHERE i.cancer_code IS NULL

UNION ALL

SELECT 'mortality' AS source_table, e.cancer_code, e.year, e.sex, e.age_group
FROM mortality_expected AS e
LEFT JOIN mortality AS m
  ON e.cancer_code = m.cancer_code AND e.year = m.year
 AND e.sex = m.sex AND e.age_group = m.age_group
WHERE m.cancer_code IS NULL;

