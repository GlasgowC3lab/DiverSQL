WITH sampled_inventory AS (
    SELECT inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
warehouse_inventory AS (
    SELECT w.w_warehouse_sk,
           w.w_warehouse_id,
           w.w_city,
           w.w_state,
           COALESCE(inv_agg.total_qty, 0) AS total_qty
    FROM warehouse w
    LEFT JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS total_qty
        FROM sampled_inventory si
        WHERE si.inv_warehouse_sk = w.w_warehouse_sk
    ) inv_agg ON TRUE
),
store_sales_filtered AS (
    SELECT ss.ss_store_sk,
           ss.ss_net_profit,
           ss.ss_quantity
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cd.cd_gender, '^F')
      AND ss.ss_store_sk NOT IN (SELECT s.s_store_sk FROM store s WHERE s.s_state = 'CA')
),
store_agg AS (
    SELECT s.s_store_id AS entity_id,
           CONCAT(s.s_city, '-', s.s_state) AS location,
           SUM(ssf.ss_net_profit) AS profit,
           COUNT(*) AS txn_cnt
    FROM store s
    JOIN store_sales_filtered ssf ON s.s_store_sk = ssf.ss_store_sk
    GROUP BY s.s_store_id, s.s_city, s.s_state
),
web_sales_agg AS (
    SELECT w.w_warehouse_id AS entity_id,
           CONCAT(w.w_city, '-', w.w_state) AS location,
           SUM(ws.ws_net_profit) AS profit,
           CAST(NULL AS integer) AS txn_cnt
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_extract(sm.sm_contract, '([A-Z]{3})') = 'AAA'
      AND w.w_city LIKE '%ville%'
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state
),
union_all AS (
    SELECT entity_id, location, profit, txn_cnt FROM store_agg
    UNION
    SELECT entity_id, location, profit, txn_cnt FROM web_sales_agg
)
SELECT ua.entity_id,
       ua.location,
       ua.profit,
       ua.txn_cnt
FROM union_all ua
WHERE ua.profit > (SELECT avg(cs.cs_net_profit) FROM catalog_sales cs)
ORDER BY ua.profit DESC
LIMIT 100
