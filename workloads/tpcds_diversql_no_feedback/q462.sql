WITH base AS (
  SELECT
    sr.sr_ticket_number,
    d.d_year,
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    r.r_reason_desc,
    sr.sr_return_amt,
    ws.ws_net_profit,
    wp.wp_type,
    we.web_name
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d.d_year = 2001
    AND ib.ib_upper_bound >= 100000
    AND w.w_warehouse_sq_ft > 50000
),
agg AS (
  SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    ca_state,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
  FROM base
  WHERE NOT EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_item_sk = base.i_item_sk
      AND inv2.inv_quantity_on_hand = 0
  )
  GROUP BY i_item_sk, i_item_id, i_product_name, ca_state
  HAVING SUM(sr_return_amt) > 10000
)
SELECT
  i_item_id,
  i_product_name,
  ca_state,
  total_return_amount,
  total_net_profit,
  transaction_count,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_return_amount DESC) AS rn_state,
  RANK() OVER (ORDER BY total_return_amount DESC) AS global_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
