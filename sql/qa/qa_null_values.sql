-- Return fact rows with NULL keys or counts; published rate NULLs are permitted.

SELECT 'incidence' AS source_table, cancer_code, year, sex, age_group, count
FROM incidence
WHERE cancer_code IS NULL OR year IS NULL OR sex IS NULL OR age_group IS NULL OR count IS NULL

UNION ALL

SELECT 'mortality' AS source_table, cancer_code, year, sex, age_group, count
FROM mortality
WHERE cancer_code IS NULL OR year IS NULL OR sex IS NULL OR age_group IS NULL OR count IS NULL;

