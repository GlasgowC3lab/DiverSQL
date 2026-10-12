WITH catalog_items AS (
    SELECT DISTINCT i.i_item_id
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 9 AND 12
      AND p.p_channel_email = 'Y'
),
store_items AS (
    SELECT DISTINCT i.i_item_id
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_quantity > 5
      AND ss.ss_net_profit > 0
      AND t.t_hour BETWEEN 14 AND 17
)
SELECT i_item_id
FROM catalog_items
INTERSECT
SELECT i_item_id
FROM store_items
LIMIT 100
