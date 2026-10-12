SELECT
  w.w_warehouse_name,
  date_format(sale_date.d_date, '%Y-%m') AS year_month,
  sum(ws.ws_net_paid) AS total_sales,
  sum(ws.ws_net_profit) AS total_profit,
  sum(coalesce(wr.wr_refunded_cash, 0)) AS total_refunds,
  sum(ws.ws_net_profit) - sum(coalesce(wr.wr_refunded_cash, 0)) AS net_profit_after_returns,
  sum(ws.ws_quantity) AS total_qty_sold,
  sum(coalesce(wr.wr_return_quantity, 0)) AS total_qty_returned,
  avg(
    case 
      when wr.wr_returned_date_sk IS NOT NULL then date_diff('day', sale_date.d_date, return_date.d_date)
      else null
    end
  ) AS avg_days_to_return
FROM web_sales ws
JOIN date_dim sale_date
  ON ws.ws_sold_date_sk = sale_date.d_date_sk
LEFT JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
  AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN date_dim return_date
  ON wr.wr_returned_date_sk = return_date.d_date_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE sale_date.d_fy_year = 1903
GROUP BY w.w_warehouse_name, date_format(sale_date.d_date, '%Y-%m')
ORDER BY net_profit_after_returns DESC
LIMIT 100
