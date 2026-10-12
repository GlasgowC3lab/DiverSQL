SELECT d.d_year,
       sum(cs.cs_ext_sales_price) AS total_sales,
       sum(cs.cs_net_profit) AS total_profit,
       count(*) AS transaction_count
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 1998
GROUP BY d.d_year
ORDER BY d.d_year
