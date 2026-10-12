WITH sales_agg AS (
    SELECT cs_item_sk,
           SUM(cs_ext_sales_price) AS total_sales,
           SUM(cs_net_profit)      AS total_profit
    FROM catalog_sales
    GROUP BY cs_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    sm.sm_type,
    ca.ca_state,
    cd.cd_gender,
    t_cr.t_hour,
    cr.cr_return_amount,
    ws.ws_net_paid,
    wr.wr_return_amt,
    sr.sr_return_amt,
    sales_agg.total_sales,
    sales_agg.total_profit
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk      = cs.cs_item_sk
JOIN sales_agg
  ON cs.cs_item_sk = sales_agg.cs_item_sk
JOIN time_dim t_cr
  ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN web_sales ws
  ON ws.ws_order_number = cr.cr_order_number
JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
WHERE cs.cs_sales_price > (
    SELECT MAX(cs2.cs_sales_price)
    FROM catalog_sales cs2
)
GROUP BY
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    sm.sm_type,
    ca.ca_state,
    cd.cd_gender,
    t_cr.t_hour,
    cr.cr_return_amount,
    ws.ws_net_paid,
    wr.wr_return_amt,
    sr.sr_return_amt,
    sales_agg.total_sales,
    sales_agg.total_profit
ORDER BY sales_agg.total_sales DESC
LIMIT 100
