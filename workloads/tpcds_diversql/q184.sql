WITH
  store_agg AS (
    SELECT
      ss_promo_sk,
      COUNT(*) AS store_txn_cnt,
      SUM(ss_ext_discount_amt) AS store_total_discount,
      AVG(ss_sales_price) AS store_avg_price
    FROM tpcds.store_sales
    WHERE ss_ext_discount_amt > 1000.00            -- realistic filter on discount amount
      AND ss_sales_price > 5.00                     -- filter on price
    GROUP BY ss_promo_sk
  ),
  web_agg AS (
    SELECT
      ws_promo_sk,
      ws_warehouse_sk,
      COUNT(*) AS web_txn_cnt,
      SUM(ws_ext_ship_cost) AS web_total_ship,
      SUM(ws_net_paid_inc_tax) AS web_total_paid
    FROM tpcds.web_sales
    WHERE ws_ext_ship_cost < 500.00                -- realistic filter on shipping cost
      AND ws_net_paid_inc_tax > 100.00             -- filter on net paid
    GROUP BY ws_promo_sk, ws_warehouse_sk
  )
SELECT
  p.p_promo_id,
  p.p_promo_name,
  p.p_channel_tv,
  w.w_warehouse_name,
  s.store_txn_cnt,
  wb.web_txn_cnt,
  s.store_total_discount,
  wb.web_total_ship,
  CASE
    WHEN s.store_total_discount > 5000.00 THEN 'HIGH_DISCOUNT'
    ELSE 'LOW_DISCOUNT'
  END AS discount_category,
  la.ratio
FROM tpcds.promotion p
JOIN store_agg s
  ON s.ss_promo_sk = p.p_promo_sk
JOIN web_agg wb
  ON wb.ws_promo_sk = p.p_promo_sk
JOIN tpcds.warehouse w
  ON w.w_warehouse_sk = wb.ws_warehouse_sk
CROSS JOIN LATERAL (
  SELECT CASE
           WHEN s.store_total_discount = 0 THEN NULL
           ELSE wb.web_total_ship / s.store_total_discount
         END AS ratio
) la
WHERE p.p_channel_tv = 'N'               -- selective predicate on promotion channel
  AND p.p_channel_email = 'N'            -- another predicate on promotion channel
  AND w.w_state = 'CA'                   -- filter on warehouse location
ORDER BY s.store_total_discount DESC
LIMIT 100
