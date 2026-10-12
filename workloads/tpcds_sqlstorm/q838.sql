SELECT d.d_year,
       i.i_category,
       s.s_state,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(COALESCE(sr.sr_net_loss, 0)) AS total_returns,
       SUM(ss.ss_net_paid) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_income
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
                         AND ss.ss_store_sk = sr.sr_store_sk
                         AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, i.i_category, s.s_state
ORDER BY net_income DESC
LIMIT 100
