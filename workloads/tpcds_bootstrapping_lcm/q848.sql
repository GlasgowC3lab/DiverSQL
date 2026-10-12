SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_sold.d_year AS sale_year,
    d_sold.d_current_month AS sale_month,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_net_loss,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    AVG(cs.cs_ext_tax) AS avg_tax_amount,
    cc.cc_tax_percentage,
    cc.cc_gmt_offset,
    (SUM(cs.cs_net_paid) - SUM(COALESCE(cr.cr_net_loss, 0))) AS net_revenue_after_returns,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_status
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_sold.d_year BETWEEN 1999 AND 2001
  AND d_cc_open.d_year < 2000
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_current_month,
    cc.cc_tax_percentage,
    cc.cc_gmt_offset
