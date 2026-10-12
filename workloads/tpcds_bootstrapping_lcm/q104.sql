SELECT
    cc.cc_manager,
    s.s_division_id,
    CONCAT(CAST(d_returned.d_year AS varchar), '-', LPAD(CAST(d_returned.d_moy AS varchar), 2, '0')) AS year_month,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(s.s_floor_space) AS avg_floor_space,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    COUNT(DISTINCT wp.wp_customer_sk) AS distinct_web_customers,
    CASE
        WHEN SUM(sr.sr_return_amt) > 0 THEN SUM(sr.sr_return_tax) / SUM(sr.sr_return_amt)
        ELSE NULL
    END AS avg_tax_rate,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax_pct
FROM store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_returned
    ON sr.sr_returned_date_sk = d_returned.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_returned.d_year BETWEEN 2015 AND 2020
  AND wp.wp_type = 'product'
  AND s.s_division_id IS NOT NULL
GROUP BY
    cc.cc_manager,
    s.s_division_id,
    d_returned.d_year,
    d_returned.d_moy
HAVING COUNT(*) > 20
ORDER BY total_net_loss DESC
LIMIT 100
