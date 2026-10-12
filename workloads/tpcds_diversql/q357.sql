WITH store_sales_agg AS (
   SELECT ss_item_sk,
          ss_sold_date_sk,
          ss_sold_time_sk,
          SUM(ss_net_profit) AS total_store_profit,
          SUM(ss_quantity)   AS total_store_qty
   FROM store_sales
   WHERE ss_net_profit > 0
   GROUP BY ss_item_sk, ss_sold_date_sk, ss_sold_time_sk
),
top_items AS (
   SELECT ss_item_sk,
          ROW_NUMBER() OVER (ORDER BY total_store_profit DESC) AS rn
   FROM store_sales_agg
   WHERE total_store_profit IS NOT NULL
),
selected_items AS (
   SELECT ss_item_sk
   FROM top_items
   WHERE rn <= 5
),
hour_vals AS (
   SELECT t_hour
   FROM time_dim
   WHERE t_hour BETWEEN 9 AND 11
),
promo_vals AS (
   SELECT 'PROMO_A' AS promo UNION ALL SELECT 'PROMO_B' AS promo
)
SELECT
   i.i_item_id,
   i.i_product_name,
   td.t_hour,
   pv.promo,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   ws.ws_net_paid               AS web_net_paid,
   ss_agg.total_store_profit,
   RANK() OVER (PARTITION BY i.i_item_id ORDER BY ss_agg.total_store_profit DESC) AS profit_rank,
   CASE
       WHEN ss_agg.total_store_profit > ws.ws_net_paid THEN 'Store Better'
       ELSE 'Web Better'
   END                         AS better_channel
FROM selected_items si
JOIN store_sales_agg ss_agg
  ON si.ss_item_sk = ss_agg.ss_item_sk
JOIN store_sales ss_raw
  ON ss_raw.ss_item_sk   = ss_agg.ss_item_sk
 AND ss_raw.ss_sold_date_sk = ss_agg.ss_sold_date_sk
 AND ss_raw.ss_sold_time_sk = ss_agg.ss_sold_time_sk
JOIN household_demographics hd
  ON ss_raw.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON ss_raw.ss_addr_sk = ca.ca_address_sk
JOIN item i
  ON ss_agg.ss_item_sk = i.i_item_sk
JOIN time_dim td
  ON ss_agg.ss_sold_time_sk = td.t_time_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
CROSS JOIN hour_vals hv
CROSS JOIN promo_vals pv
WHERE sm.sm_code = 'AIR'
  AND r.r_reason_desc LIKE '%price%'
  AND ib.ib_upper_bound > 50000
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_return_amt > 1000
      )
EXCEPT
SELECT
   i.i_item_id,
   i.i_product_name,
   td.t_hour,
   pv.promo,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   ws.ws_net_paid,
   ss_agg.total_store_profit,
   RANK() OVER (PARTITION BY i.i_item_id ORDER BY ss_agg.total_store_profit DESC),
   CASE
       WHEN ss_agg.total_store_profit > ws.ws_net_paid THEN 'Store Better'
       ELSE 'Web Better'
   END
FROM selected_items si
JOIN store_sales_agg ss_agg
  ON si.ss_item_sk = ss_agg.ss_item_sk
JOIN store_sales ss_raw
  ON ss_raw.ss_item_sk   = ss_agg.ss_item_sk
 AND ss_raw.ss_sold_date_sk = ss_agg.ss_sold_date_sk
 AND ss_raw.ss_sold_time_sk = ss_agg.ss_sold_time_sk
JOIN household_demographics hd
  ON ss_raw.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON ss_raw.ss_addr_sk = ca.ca_address_sk
JOIN item i
  ON ss_agg.ss_item_sk = i.i_item_sk
JOIN time_dim td
  ON ss_agg.ss_sold_time_sk = td.t_time_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
CROSS JOIN hour_vals hv
CROSS JOIN promo_vals pv
WHERE sm.sm_code = 'AIR'
  AND r.r_reason_desc LIKE '%price%'
  AND ib.ib_upper_bound > 50000
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_return_amt > 1000
      )
LIMIT 100
