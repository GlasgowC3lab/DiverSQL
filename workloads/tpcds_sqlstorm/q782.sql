SELECT
    d.d_year,
    i.i_category,
    i.i_class,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND s.s_gmt_offset > -5
  AND r.r_reason_desc LIKE '%Customer%'
GROUP BY d.d_year, i.i_category, i.i_class
ORDER BY total_profit DESC
LIMIT 100
