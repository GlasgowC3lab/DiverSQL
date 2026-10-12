WITH intersect_items AS (
    SELECT ss_item_sk AS item_sk
    FROM store_sales
    WHERE ss_quantity > 5
    GROUP BY ss_item_sk
    INTERSECT
    SELECT ws_item_sk AS item_sk
    FROM web_sales
    WHERE ws_quantity > 5
    GROUP BY ws_item_sk
),
store_agg AS (
    SELECT ss_item_sk,
           SUM(ss_net_profit) AS total_store_profit,
           COUNT(DISTINCT ss_customer_sk) AS store_customer_cnt
    FROM store_sales
    WHERE ss_quantity > 5
    GROUP BY ss_item_sk
),
web_agg AS (
    SELECT ws_item_sk,
           SUM(ws_net_profit) AS total_web_profit,
           COUNT(DISTINCT ws_bill_customer_sk) AS web_customer_cnt
    FROM web_sales
    WHERE ws_quantity > 5
    GROUP BY ws_item_sk
)
SELECT i.i_item_id,
       i.i_product_name,
       sa.total_store_profit,
       sa.store_customer_cnt,
       wa.total_web_profit,
       wa.web_customer_cnt
FROM intersect_items ii
JOIN item i
  ON i.i_item_sk = ii.item_sk
JOIN store_agg sa
  ON sa.ss_item_sk = ii.item_sk
JOIN web_agg wa
  ON wa.ws_item_sk = ii.item_sk
ORDER BY sa.total_store_profit DESC
LIMIT 100
