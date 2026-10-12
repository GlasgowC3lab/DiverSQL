WITH cs_filtered AS (
        SELECT *
        FROM catalog_sales
        WHERE cs_order_number NOT IN (SELECT cr_order_number FROM catalog_returns)
    ),
    ws_filtered AS (
        SELECT *
        FROM web_sales
        WHERE ws_order_number NOT IN (SELECT wr_order_number FROM web_returns)
    ),
    catalog_agg AS (
        SELECT
            w.w_warehouse_id        AS warehouse_id,
            i.i_item_id            AS item_id,
            SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_sales
        FROM cs_filtered cs
        FULL OUTER JOIN inventory inv
            ON cs.cs_item_sk = inv.inv_item_sk
           AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
        JOIN warehouse w
            ON COALESCE(cs.cs_warehouse_sk, inv.inv_warehouse_sk) = w.w_warehouse_sk
        JOIN item i
            ON COALESCE(cs.cs_item_sk, inv.inv_item_sk) = i.i_item_sk
        GROUP BY ROLLUP (w.w_warehouse_id, i.i_item_id)
    ),
    web_agg AS (
        SELECT
            w.w_warehouse_id        AS warehouse_id,
            i.i_item_id            AS item_id,
            SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales
        FROM ws_filtered ws
        FULL OUTER JOIN inventory inv
            ON ws.ws_item_sk = inv.inv_item_sk
           AND ws.ws_warehouse_sk = inv.inv_warehouse_sk
        JOIN warehouse w
            ON COALESCE(ws.ws_warehouse_sk, inv.inv_warehouse_sk) = w.w_warehouse_sk
        JOIN item i
            ON COALESCE(ws.ws_item_sk, inv.inv_item_sk) = i.i_item_sk
        GROUP BY ROLLUP (w.w_warehouse_id, i.i_item_id)
    )
SELECT warehouse_id,
       item_id,
       total_sales
FROM catalog_agg
UNION
SELECT warehouse_id,
       item_id,
       total_sales
FROM web_agg
ORDER BY warehouse_id,
         item_id
LIMIT 100
