SELECT 
    cd.cd_education_status,
    cd.cd_gender,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(*) AS cust_cnt,
    SUM(ws.web_tax_percentage) AS total_tax_percentage,
    COUNT(DISTINCT ws.web_site_id) AS distinct_site_cnt
FROM customer_demographics cd
CROSS JOIN web_site ws
WHERE cd.cd_credit_rating = 'Good'
  AND ws.web_country = 'United States'
  AND ws.web_gmt_offset BETWEEN -5 AND 5
GROUP BY cd.cd_education_status, cd.cd_gender
HAVING COUNT(*) > 100
ORDER BY avg_purchase_estimate DESC
LIMIT 50
