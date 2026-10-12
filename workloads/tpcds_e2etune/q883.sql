WITH sales_agg AS (
  SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    t.t_hour,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    AVG(cs.cs_quantity) AS avg_quantity
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE cp.cp_catalog_page_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAACAAAAAAA')
    AND t.t_hour BETWEEN 9 AND 17
    AND cp.cp_start_date_sk >= 2450800
  GROUP BY cp.cp_catalog_page_id, cp.cp_catalog_page_number, t.t_hour
  HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
  cp_catalog_page_id,
  cp_catalog_page_number,
  t_hour,
  order_cnt,
  total_profit,
  total_sales,
  avg_discount,
  avg_quantity,
  ROW_NUMBER() OVER (PARTITION BY cp_catalog_page_number ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
