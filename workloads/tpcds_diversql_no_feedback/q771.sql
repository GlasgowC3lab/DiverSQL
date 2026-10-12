WITH
  ws_agg AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      any_value(ws_ship_mode_sk)   AS ship_mode_sk,
      any_value(ws_warehouse_sk)   AS warehouse_sk,
      any_value(ws_web_site_sk)    AS web_site_sk,
      sum(ws_ext_sales_price)      AS total_sales,
      sum(ws_net_profit)           AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2002
    )
    GROUP BY ws_item_sk, ws_sold_date_sk
  ),
  returns_filtered AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_reason_sk,
      sr.sr_hdemo_sk,
      sr.sr_addr_sk,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sum(sr.sr_return_amt_inc_tax) AS sum_return_amt,
      count(*)                        AS cnt_returns
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2002
          )
      AND sr.sr_reason_sk IN (
            SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%damage%'
          )
      AND sr.sr_return_quantity > 0
      AND sr.sr_reversed_charge > 0
    GROUP BY
      sr.sr_store_sk,
      sr.sr_reason_sk,
      sr.sr_hdemo_sk,
      sr.sr_addr_sk,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk
  )
SELECT
  COALESCE(s.s_store_name, 'No Store')                     AS store_name,
  r.r_reason_desc                                         AS return_reason,
  d_ret.d_year                                            AS return_year,
  ca.ca_city                                              AS customer_city,
  CASE
    WHEN ib.ib_upper_bound < 50000 THEN 'Low Income'
    ELSE 'High Income'
  END                                                     AS income_category,
  sm.sm_type                                              AS ship_mode_type,
  w.w_warehouse_name                                      AS warehouse_name,
  we.web_name                                             AS website_name,
  rf.cnt_returns                                          AS return_transactions,
  rf.sum_return_amt                                       AS total_return_amount,
  ws.total_sales                                          AS total_sales,
  ws.total_profit                                         AS total_profit,
  (rf.sum_return_amt / ws.total_sales) * 100            AS return_to_sales_pct
FROM returns_filtered rf
FULL OUTER JOIN store s
  ON rf.sr_store_sk = s.s_store_sk
LEFT JOIN reason r
  ON rf.sr_reason_sk = r.r_reason_sk
LEFT JOIN household_demographics hd
  ON rf.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_address ca
  ON rf.sr_addr_sk = ca.ca_address_sk
LEFT JOIN date_dim d_ret
  ON rf.sr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN time_dim td_ret
  ON rf.sr_return_time_sk = td_ret.t_time_sk
LEFT JOIN ws_agg ws
  ON ws.ws_sold_date_sk = rf.sr_returned_date_sk
LEFT JOIN ship_mode sm
  ON ws.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
  ON ws.warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_site we
  ON ws.web_site_sk = we.web_site_sk
WHERE ib.ib_lower_bound > 20000
  AND s.s_state = 'CA'
  AND ca.ca_country = 'United States'
  AND sm.sm_carrier = 'UPS'
ORDER BY ws.total_sales DESC
LIMIT 100
