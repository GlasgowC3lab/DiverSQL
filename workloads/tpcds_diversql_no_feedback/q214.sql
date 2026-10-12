SELECT
  order_number,
  year,
  web_site_sk,
  warehouse_sk,
  warehouse_name,
  total_net_profit,
  total_return_amount,
  total_net_profit - total_return_amount AS net_profit_after_returns,
  LAG(total_net_profit - total_return_amount) OVER (PARTITION BY web_site_sk ORDER BY year) AS prior_year_net_profit
FROM (
  SELECT
    ws.ws_order_number AS order_number,
    d_sold.d_year AS year,
    ws.ws_web_site_sk AS web_site_sk,
    ws.ws_warehouse_sk AS warehouse_sk,
    w.w_warehouse_name AS warehouse_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN date_dim d_site_open
    ON ws_site.web_open_date_sk = d_site_open.d_date_sk
  JOIN call_center cc
    ON cc.cc_open_date_sk = d_site_open.d_date_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
  LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  WHERE EXISTS (
    SELECT 1
    FROM call_center cc2
    WHERE cc2.cc_manager = ws_site.web_manager
      AND cc2.cc_state = ws_site.web_state
  )
  GROUP BY
    ws.ws_order_number,
    d_sold.d_year,
    ws.ws_web_site_sk,
    ws.ws_warehouse_sk,
    w.w_warehouse_name
) q
ORDER BY year DESC, total_net_profit DESC
LIMIT 100
