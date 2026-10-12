WITH joined_data AS (
  SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    p.p_discount_active,
    t.t_shift,
    ca.ca_state,
    hd.hd_income_band_sk,
    ss.ss_net_profit,
    COALESCE(sr.sr_net_loss, 0) AS sr_net_loss,
    COALESCE(cr.cr_net_loss, 0) AS cr_net_loss,
    COALESCE(wr.wr_net_loss, 0) AS wr_net_loss,
    r.r_reason_desc,
    sm.sm_type,
    cc.cc_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = ss.ss_item_sk
   AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
  LEFT JOIN web_sales ws
    ON ws.ws_item_sk = ss.ss_item_sk
   AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Electronics'
    AND t.t_shift = 'first'
    AND ca.ca_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
),
aggregated AS (
  SELECT
    d_year,
    i_category,
    p_promo_name,
    SUM(ss_net_profit) AS total_profit,
    SUM(sr_net_loss + cr_net_loss + wr_net_loss) AS total_loss,
    COUNT(*) AS sales_cnt
  FROM joined_data
  GROUP BY d_year, i_category, p_promo_name
  HAVING SUM(ss_net_profit) > 10000
     AND COUNT(*) > 100
)
SELECT
  d_year,
  i_category,
  p_promo_name,
  total_profit,
  total_loss,
  total_profit / NULLIF(total_loss, 0) AS profit_loss_ratio,
  ROW_NUMBER() OVER (ORDER BY (total_profit / NULLIF(total_loss, 0)) DESC) AS rn
FROM aggregated
ORDER BY profit_loss_ratio DESC
LIMIT 100
