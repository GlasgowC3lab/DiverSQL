SELECT
    cc.cc_city,
    s.s_state,
    p.p_promo_name,
    dr.d_year,
    dr.d_month_seq,
    ds.d_quarter_name AS cc_closed_quarter,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_fee) AS total_gross_loss,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(CASE WHEN cr.cr_return_amount > 1000 THEN 1 ELSE 0 END) AS high_value_return_cnt,
    SUM(cr.cr_return_amount * (1 + cc.cc_tax_percentage / 100) * (1 + s.s_tax_percentage / 100)) AS adjusted_return_amount,
    ROUND(AVG(cc.cc_tax_percentage), 2) AS avg_center_tax_pct,
    ROUND(AVG(s.s_tax_percentage), 2) AS avg_store_tax_pct,
    ROUND(AVG(cc.cc_tax_percentage) - AVG(s.s_tax_percentage), 2) AS tax_pct_diff
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = dr.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim ds
    ON cc.cc_closed_date_sk = ds.d_date_sk
WHERE dr.d_year = 2022
  AND dr.d_date_sk <= p.p_end_date_sk
  AND p.p_discount_active = 'Y'
GROUP BY
    cc.cc_city,
    s.s_state,
    p.p_promo_name,
    dr.d_year,
    dr.d_month_seq,
    ds.d_quarter_name
ORDER BY total_return_amount DESC
LIMIT 100
