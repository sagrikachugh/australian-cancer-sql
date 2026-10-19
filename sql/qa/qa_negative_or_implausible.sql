-- Return negative values or implausibly large published rates; zero rows is a pass.

SELECT 'incidence' AS source_table, cancer_code, year, sex, age_group, count, published_rate, asr
FROM incidence
WHERE count < 0 OR published_rate < 0 OR asr < 0 OR published_rate > 5000 OR asr > 5000

UNION ALL

SELECT 'mortality' AS source_table, cancer_code, year, sex, age_group, count, published_rate, asr
FROM mortality
WHERE count < 0 OR published_rate < 0 OR asr < 0 OR published_rate > 5000 OR asr > 5000;

