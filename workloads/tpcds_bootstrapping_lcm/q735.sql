SELECT
    d.d_year,
    d.d_moy AS month,
    CASE
        WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
        WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
        ELSE 'Other'
    END AS region,
    hd_refund.hd_buy_potential,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) AS total_return_amount,
    CASE
        WHEN (COUNT(DISTINCT cr.cr_order_number) + COUNT(DISTINCT wr.wr_order_number)) = 0 THEN 0
        ELSE (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) /
            (COUNT(DISTINCT cr.cr_order_number) + COUNT(DISTINCT wr.wr_order_number))
    END AS avg_return_amount_per_order,
    (SUM(cr.cr_fee) + SUM(wr.wr_fee)) AS total_fees,
    (SUM(cr.cr_return_ship_cost) + SUM(wr.wr_return_ship_cost)) AS total_ship_cost,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN s.s_number_employees > 100 THEN 1 ELSE 0 END) AS large_store_closed_cnt
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_refund
  ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_wref
  ON wr.wr_refunded_hdemo_sk = hd_wref.hd_demo_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2000
  AND hd_wref.hd_income_band_sk >= 3
GROUP BY
    d.d_year,
    d.d_moy,
    CASE
        WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
        WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
        ELSE 'Other'
    END,
    hd_refund.hd_buy_potential
HAVING (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 0
ORDER BY d.d_year DESC, d.d_moy DESC, region
LIMIT 100
