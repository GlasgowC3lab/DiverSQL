SELECT
    d.d_year,
    s.s_state,
    sum(ss.ss_ext_sales_price) AS total_sales,
    sum(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, s.s_state
ORDER BY d.d_year, s.s_state
