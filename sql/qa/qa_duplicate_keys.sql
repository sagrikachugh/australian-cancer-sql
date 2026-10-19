-- Return duplicate rows at the declared fact-table grain; zero rows is a pass.

SELECT 'incidence' AS source_table, cancer_code, year, sex, age_group, COUNT(*) AS n_rows
FROM incidence
GROUP BY cancer_code, year, sex, age_group
HAVING COUNT(*) > 1

UNION ALL

SELECT 'mortality' AS source_table, cancer_code, year, sex, age_group, COUNT(*) AS n_rows
FROM mortality
GROUP BY cancer_code, year, sex, age_group
HAVING COUNT(*) > 1;

