WITH monthly_total AS (
    SELECT d.d_year, d.d_moy, SUM(ss.ss_net_paid) AS month_total
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_moy
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_moy AS month,
    i.i_category,
    i.i_brand,
    SUM(ss.ss_net_paid) AS store_month_net_paid,
    SUM(ss.ss_net_profit) AS store_month_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    mt.month_total,
    (SUM(ss.ss_net_paid) / mt.month_total) * 100 AS pct_of_monthly_revenue
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN monthly_total mt ON d.d_year = mt.d_year AND d.d_moy = mt.d_moy
WHERE s.s_state = 'CA'
  AND d.d_year BETWEEN 1999 AND 2001
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_moy,
    i.i_category,
    i.i_brand,
    mt.month_total
ORDER BY store_month_net_profit DESC
LIMIT 100
