SELECT
    d_ret.d_year AS return_year,
    d_s.d_year AS store_closed_year,
    cc.cc_state AS call_center_state,
    s.s_state AS store_state,
    ca_ref.ca_state AS refunded_state,
    ca_ret.ca_state AS returning_state,
    CASE WHEN cc.cc_tax_percentage > 10 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category,
    CASE WHEN d_ret.d_month_seq % 2 = 0 THEN 'EVEN_MONTH' ELSE 'ODD_MONTH' END AS month_parity,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_quantity) AS total_quantity
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cc.d_date_sk
JOIN date_dim d_s ON s.s_closed_date_sk = d_s.d_date_sk
JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
WHERE cc.cc_division = s.s_division_id
  AND d_ret.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_ret.d_year,
    d_s.d_year,
    cc.cc_state,
    s.s_state,
    ca_ref.ca_state,
    ca_ret.ca_state,
    CASE WHEN cc.cc_tax_percentage > 10 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END,
    CASE WHEN d_ret.d_month_seq % 2 = 0 THEN 'EVEN_MONTH' ELSE 'ODD_MONTH' END
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
