WITH sampled_catalog AS (
  SELECT *
  FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
joined AS (
  SELECT
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_net_profit,
    d_cs.d_year,
    ca_cs.ca_state,
    cd_cs.cd_credit_rating,
    w.w_warehouse_name,
    p.p_promo_name,
    cc.cc_name,
    ws.ws_quantity AS ws_quantity,
    ws.ws_sales_price AS ws_sales_price,
    ws.ws_net_profit AS ws_net_profit,
    wr.wr_return_quantity,
    wr.wr_net_loss,
    s.s_store_name,
    t_cs.t_hour,
    wp.wp_type,
    we.web_name,
    ARRAY[cs.cs_quantity, CAST(cs.cs_sales_price AS double)] AS qty_price_arr
  FROM sampled_catalog cs
  JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
  JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
  JOIN web_sales ws ON cs.cs_item_sk = ws.ws_item_sk AND cs.cs_order_number = ws.ws_order_number
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  JOIN store_returns sr ON sr.sr_returned_date_sk = d_wr.d_date_sk
  JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d_cs.d_year = 2001
    AND ca_cs.ca_state = 'TX'
    AND cd_cs.cd_credit_rating = 'Good'
    AND w.w_gmt_offset BETWEEN -5 AND 0
    AND p.p_discount_active = 'Y'
)
SELECT
  j.cs_order_number,
  j.d_year,
  j.ca_state,
  j.cd_credit_rating,
  j.p_promo_name,
  j.cc_name,
  j.w_warehouse_name,
  j.s_store_name,
  j.t_hour,
  j.wp_type,
  j.web_name,
  unnested.price_or_qty,
  unnested.element_position,
  SUM(j.cs_net_profit) OVER (PARTITION BY j.p_promo_name ORDER BY j.cs_net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
  RANK() OVER (PARTITION BY j.d_year ORDER BY j.cs_net_profit DESC) AS profit_rank
FROM joined j
CROSS JOIN UNNEST(j.qty_price_arr) WITH ORDINALITY AS unnested(price_or_qty, element_position)
ORDER BY j.d_year, profit_rank
LIMIT 100
