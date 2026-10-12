SELECT
    dr.d_year,
    dr.d_month_seq,
    CASE WHEN dr.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_state,
    s.s_city,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT p.p_promo_id) AS active_promo_cnt,
    AVG(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost END) AS avg_active_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_active_promo_cost
FROM web_returns wr
JOIN date_dim dr
    ON wr.wr_returned_date_sk = dr.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = dr.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
CROSS JOIN promotion p
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE dr.d_date_sk BETWEEN d_start.d_date_sk AND d_end.d_date_sk
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    CASE WHEN dr.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    s.s_state,
    s.s_city
HAVING
    SUM(wr.wr_return_amt) > 10000
ORDER BY total_return_amount DESC
LIMIT 100
