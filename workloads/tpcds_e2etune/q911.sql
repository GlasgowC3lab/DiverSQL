WITH aggregated AS (
  SELECT
    cc.cc_name AS call_center_name,
    p.p_promo_name AS promotion_name,
    w.w_city AS warehouse_city,
    cp.cp_type AS catalog_page_type,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim p_start ON p.p_start_date_sk = p_start.d_date_sk
  JOIN date_dim p_end ON p.p_end_date_sk = p_end.d_date_sk
  WHERE sd.d_year = 2001
    AND sd.d_qoy = 1
    AND sd.d_date_sk BETWEEN p_start.d_date_sk AND p_end.d_date_sk
  GROUP BY
    cc.cc_name,
    p.p_promo_name,
    w.w_city,
    cp.cp_type
  HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
  call_center_name,
  promotion_name,
  warehouse_city,
  catalog_page_type,
  total_net_profit,
  avg_discount_amount,
  sales_cnt,
  RANK() OVER (PARTITION BY promotion_name ORDER BY total_net_profit DESC) AS profit_rank_by_promo
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 10
