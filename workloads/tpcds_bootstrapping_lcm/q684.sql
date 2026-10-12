SELECT
    d.d_year,
    d.d_month_seq AS month_number,
    sm.sm_type,
    CASE
        WHEN s.s_state IN ('CA','NY','TX') THEN s.s_state
        ELSE 'Other'
    END AS region_state,
    wp.wp_type,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amt,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_return_amount * cr.cr_return_quantity) AS weighted_return_amt,
    SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_return_ship_cost + cr.cr_fee) AS total_gross_return,
    CASE
        WHEN SUM(cr.cr_return_amount) > 20000 THEN 'Very High'
        WHEN SUM(cr.cr_return_amount) > 10000 THEN 'High'
        WHEN SUM(cr.cr_return_amount) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category,
    SUM(cr.cr_return_ship_cost) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_ship_cost_per_item,
    SUM(cr.cr_fee) / NULLIF(COUNT(*), 0) AS avg_fee_per_return
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year >= 2020
  AND sm.sm_type = 'AIR'
GROUP BY
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    CASE
        WHEN s.s_state IN ('CA','NY','TX') THEN s.s_state
        ELSE 'Other'
    END,
    wp.wp_type
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
