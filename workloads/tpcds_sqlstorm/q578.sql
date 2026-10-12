SELECT
    d.d_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(*) AS sales_cnt
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year
ORDER BY d.d_year
