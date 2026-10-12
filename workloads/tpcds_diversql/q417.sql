WITH first_part AS (
  SELECT
    w.w_warehouse_name,
    ib.ib_income_band_sk,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS orders
  FROM catalog_sales cs
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
  JOIN store_sales ss ON ss.ss_sold_time_sk = t_cs.t_time_sk
  JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = t_cs.t_time_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  CROSS JOIN UNNEST(ARRAY[cs.cs_promo_sk, cs.cs_ship_mode_sk]) AS u(promo_ship_key)
  WHERE EXISTS (
    SELECT 1 FROM inventory i2
    WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
      AND i2.inv_quantity_on_hand > 500
  )
  GROUP BY w.w_warehouse_name, ib.ib_income_band_sk
),
second_part AS (
  SELECT
    w2.w_warehouse_name,
    ib2.ib_income_band_sk,
    SUM(ws2.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws2.ws_order_number) AS orders
  FROM web_sales ws2
  JOIN warehouse w2 ON ws2.ws_warehouse_sk = w2.w_warehouse_sk
  JOIN household_demographics hd2 ON ws2.ws_bill_hdemo_sk = hd2.hd_demo_sk
  JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
  JOIN time_dim t_ws ON ws2.ws_sold_time_sk = t_ws.t_time_sk
  JOIN ship_mode sm2 ON ws2.ws_ship_mode_sk = sm2.sm_ship_mode_sk
  JOIN customer_address ca2 ON ws2.ws_bill_addr_sk = ca2.ca_address_sk
  JOIN inventory inv2 ON w2.w_warehouse_sk = inv2.inv_warehouse_sk
  JOIN web_returns wr2 ON wr2.wr_order_number = ws2.ws_order_number
  CROSS JOIN UNNEST(ARRAY[ws2.ws_promo_sk, ws2.ws_ship_mode_sk]) AS u2(promo_ship_key)
  WHERE EXISTS (
    SELECT 1 FROM inventory i3
    WHERE i3.inv_warehouse_sk = w2.w_warehouse_sk
      AND i3.inv_quantity_on_hand > 500
  )
  GROUP BY w2.w_warehouse_name, ib2.ib_income_band_sk
)
SELECT *
FROM (
  SELECT * FROM first_part
  UNION
  SELECT * FROM second_part
) AS combined
ORDER BY total_profit DESC
OFFSET 10
LIMIT 100
