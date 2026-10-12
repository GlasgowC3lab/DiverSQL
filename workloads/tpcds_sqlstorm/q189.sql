SELECT d.d_year,
       sum(ss.ss_ext_sales_price) AS total_revenue,
       sum(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY d.d_year
