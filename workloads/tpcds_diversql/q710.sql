WITH store_agg AS (
    SELECT ss.ss_item_sk,
           d.d_year,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ss.ss_item_sk, d.d_year
)
SELECT i.i_item_id AS item_id,
       CASE WHEN sa.total_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
       pl.promo_cnt
FROM store_agg sa
JOIN item i ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
    SELECT COUNT(DISTINCT p.p_promo_sk) AS promo_cnt
    FROM promotion p
    WHERE p.p_item_sk = i.i_item_sk
) pl ON true
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    JOIN date_dim d2 ON p2.p_start_date_sk = d2.d_date_sk
    WHERE p2.p_item_sk = i.i_item_sk
      AND d2.d_year = 2022
)
EXCEPT
SELECT i2.i_item_id AS item_id,
       'Low' AS profit_category,
       CAST(0 AS BIGINT) AS promo_cnt
FROM catalog_sales cs
JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
JOIN date_dim d3 ON cs.cs_sold_date_sk = d3.d_date_sk
WHERE d3.d_year = 2022
  AND cs.cs_net_paid > 5000
ORDER BY profit_category DESC, item_id
LIMIT 100
