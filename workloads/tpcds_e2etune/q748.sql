WITH filtered_sales AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_item_sk,
    ss.ss_net_paid,
    ss.ss_ext_discount_amt,
    ss.ss_net_profit,
    ss.ss_quantity,
    ss.ss_sold_date_sk
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
    AND ss.ss_quantity > 0
)
SELECT
  s.s_store_id,
  s.s_city,
  s.s_state,
  i.i_brand,
  i.i_category,
  SUM(fs.ss_net_paid) AS total_net_paid,
  SUM(fs.ss_ext_discount_amt) AS total_discount,
  AVG(fs.ss_net_profit) AS avg_net_profit,
  SUM(fs.ss_quantity) AS total_quantity,
  ROUND(SUM(fs.ss_net_profit) / NULLIF(SUM(fs.ss_net_paid), 0), 4) AS profit_margin,
  RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(fs.ss_net_paid) DESC) AS brand_rank_in_store
FROM filtered_sales fs
JOIN store s ON fs.ss_store_sk = s.s_store_sk
JOIN item i ON fs.ss_item_sk = i.i_item_sk
WHERE i.i_manufact_id IN (52, 294, 479)
  AND s.s_state = 'CA'
GROUP BY
  s.s_store_id,
  s.s_city,
  s.s_state,
  i.i_brand,
  i.i_category
HAVING SUM(fs.ss_net_paid) > 10000
ORDER BY s.s_state, s.s_store_id, brand_rank_in_store
LIMIT 100
