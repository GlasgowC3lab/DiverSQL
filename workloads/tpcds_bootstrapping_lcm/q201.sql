SELECT
    d.d_year,
    d.d_month_seq,
    d.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(*) AS return_count,
    CASE
        WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
        WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
        ELSE 'Other'
    END AS region
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND s.s_tax_percentage > 0
  AND d.d_year >= 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    CASE
        WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
        WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
        ELSE 'Other'
    END
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
