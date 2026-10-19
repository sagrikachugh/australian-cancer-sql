-- Return fact-table cancer codes missing from the dimension using anti-joins.

SELECT DISTINCT 'incidence' AS source_table, i.cancer_code
FROM incidence AS i
LEFT JOIN cancer_type AS c USING (cancer_code)
WHERE c.cancer_code IS NULL

UNION ALL

SELECT DISTINCT 'mortality' AS source_table, m.cancer_code
FROM mortality AS m
LEFT JOIN cancer_type AS c USING (cancer_code)
WHERE c.cancer_code IS NULL;
