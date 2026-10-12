SELECT
    d.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year IN (2000, 2001, 2002)
GROUP BY d.d_year
ORDER BY d.d_year
