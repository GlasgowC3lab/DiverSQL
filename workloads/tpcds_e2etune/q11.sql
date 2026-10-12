WITH store_agg AS (
  SELECT
    p.p_promo_id,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_ext_discount_amt) AS store_total_discount,
    COUNT(*) AS store_sales_cnt
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE p.p_discount_active = 'N'
    AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
  GROUP BY p.p_promo_id, hd.hd_income_band_sk, hd.hd_vehicle_count
),
web_agg AS (
  SELECT
    p.p_promo_id,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ws.ws_ext_discount_amt) AS web_total_discount,
    COUNT(*) AS web_sales_cnt
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE p.p_discount_active = 'N'
    AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
    AND wp.wp_type = 'product'
  GROUP BY p.p_promo_id, hd.hd_income_band_sk, hd.hd_vehicle_count
)
SELECT
  COALESCE(s.p_promo_id, w.p_promo_id) AS promo_id,
  COALESCE(s.hd_income_band_sk, w.hd_income_band_sk) AS income_band,
  COALESCE(s.hd_vehicle_count, w.hd_vehicle_count) AS vehicle_count,
  COALESCE(s.store_net_profit, 0) AS store_net_profit,
  COALESCE(w.web_net_profit, 0) AS web_net_profit,
  COALESCE(s.store_total_discount, 0) AS store_total_discount,
  COALESCE(w.web_total_discount, 0) AS web_total_discount,
  COALESCE(s.store_sales_cnt, 0) AS store_sales_cnt,
  COALESCE(w.web_sales_cnt, 0) AS web_sales_cnt,
  (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0)) AS total_net_profit,
  (COALESCE(s.store_total_discount, 0) + COALESCE(w.web_total_discount, 0)) / NULLIF((COALESCE(s.store_sales_cnt, 0) + COALESCE(w.web_sales_cnt, 0)), 0) AS avg_discount_per_sale
FROM store_agg s
FULL OUTER JOIN web_agg w
  ON s.p_promo_id = w.p_promo_id
  AND s.hd_income_band_sk = w.hd_income_band_sk
  AND s.hd_vehicle_count = w.hd_vehicle_count
ORDER BY total_net_profit DESC
LIMIT 50
