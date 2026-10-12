WITH inv_sample AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT i_manufact_id,
       sm_type,
       brand_ship,
       first_word,
       total_net_profit,
       total_quantity
FROM (
    SELECT i.i_manufact_id AS i_manufact_id,
           sm.sm_type AS sm_type,
           CONCAT(i.i_brand, ' - ', sm.sm_type) AS brand_ship,
           REGEXP_EXTRACT(i.i_product_name, '^([^ ]+)') AS first_word,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_quantity) AS total_quantity,
           ROW_NUMBER() OVER (PARTITION BY i.i_manufact_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inv_sample inv ON inv.inv_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_manufact, '^a')
      AND i.i_container LIKE '%Box%'
    GROUP BY i.i_manufact_id, sm.sm_type, i.i_brand, i.i_product_name
    HAVING SUM(ws.ws_net_profit) > 10000
) t1
WHERE rn <= 5

UNION

SELECT i_manufact_id,
       sm_type,
       brand_ship,
       first_word,
       total_net_profit,
       total_quantity
FROM (
    SELECT i.i_manufact_id AS i_manufact_id,
           sm.sm_type AS sm_type,
           CONCAT(i.i_brand, ' - ', sm.sm_type) AS brand_ship,
           REGEXP_EXTRACT(i.i_product_name, '^([^ ]+)') AS first_word,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_quantity) AS total_quantity,
           ROW_NUMBER() OVER (PARTITION BY i.i_manufact_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(i.i_manufact, 'tion$')
      AND i.i_container LIKE '%Carton%'
    GROUP BY i.i_manufact_id, sm.sm_type, i.i_brand, i.i_product_name
    HAVING SUM(ws.ws_net_profit) > 15000
) t2
WHERE rn <= 5

ORDER BY i_manufact_id, total_net_profit DESC
LIMIT 100
