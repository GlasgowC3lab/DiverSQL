WITH store_agg AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    hd.hd_income_band_sk,
    td.t_hour,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(*) AS store_sales_cnt
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE p.p_start_date_sk BETWEEN 2450000 AND 2452000
    AND td.t_hour BETWEEN 9 AND 17
  GROUP BY p.p_promo_id, p.p_promo_name, hd.hd_income_band_sk, td.t_hour
),
catalog_agg AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    hd.hd_income_band_sk,
    td.t_hour,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    COUNT(*) AS catalog_sales_cnt
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE p.p_start_date_sk BETWEEN 2450000 AND 2452000
    AND td.t_hour BETWEEN 9 AND 17
    AND cp.cp_type = 'monthly'
  GROUP BY p.p_promo_id, p.p_promo_name, hd.hd_income_band_sk, td.t_hour
)
SELECT
  COALESCE(s.p_promo_id, c.p_promo_id) AS promo_id,
  COALESCE(s.p_promo_name, c.p_promo_name) AS promo_name,
  COALESCE(s.hd_income_band_sk, c.hd_income_band_sk) AS income_band_sk,
  COALESCE(s.t_hour, c.t_hour) AS hour_of_day,
  COALESCE(s.store_net_profit, 0) AS store_net_profit,
  COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
  COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) AS total_net_profit,
  COALESCE(s.store_sales_cnt, 0) AS store_sales_cnt,
  COALESCE(c.catalog_sales_cnt, 0) AS catalog_sales_cnt,
  RANK() OVER (ORDER BY COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) DESC) AS profit_rank
FROM store_agg s
FULL OUTER JOIN catalog_agg c
  ON s.p_promo_id = c.p_promo_id
  AND s.hd_income_band_sk = c.hd_income_band_sk
  AND s.t_hour = c.t_hour
WHERE COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
