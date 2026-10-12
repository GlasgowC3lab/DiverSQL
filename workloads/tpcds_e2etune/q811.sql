SELECT
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    c.cd_gender,
    c.cd_marital_status,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_profit_after_returns,
    CASE WHEN SUM(ws.ws_quantity) > 0 THEN SUM(COALESCE(wr.wr_return_quantity, 0)) * 1.0 / SUM(ws.ws_quantity) ELSE 0 END AS return_quantity_ratio
FROM web_sales ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics c
    ON ws.ws_bill_cdemo_sk = c.cd_demo_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
WHERE c.cd_credit_rating = 'Good'
  AND c.cd_purchase_estimate >= 1500
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, c.cd_gender, c.cd_marital_status
HAVING SUM(ws.ws_quantity) > 100
ORDER BY d.d_year, d.d_month_seq, net_profit_after_returns DESC
LIMIT 200
