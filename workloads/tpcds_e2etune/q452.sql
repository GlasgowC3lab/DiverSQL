SELECT
    i.i_category,
    i.i_brand,
    sm.sm_type,
    cd.cd_marital_status,
    hd.hd_income_band_sk,
    sd.d_year AS sales_year,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
    AND cr.cr_returned_date_sk = sd.d_date_sk
LEFT JOIN date_dim rd ON cr.cr_returned_date_sk = rd.d_date_sk
JOIN store s ON s.s_closed_date_sk = sd.d_date_sk
WHERE sd.d_year = 2001
  AND sm.sm_type = 'AIR'
  AND cd.cd_marital_status = 'M'
  AND hd.hd_income_band_sk IN (1, 2, 3)
  AND s.s_state = 'CA'
GROUP BY
    i.i_category,
    i.i_brand,
    sm.sm_type,
    cd.cd_marital_status,
    hd.hd_income_band_sk,
    sd.d_year
HAVING SUM(cs.cs_net_profit) > 5000
ORDER BY net_profit_after_returns DESC
LIMIT 50
