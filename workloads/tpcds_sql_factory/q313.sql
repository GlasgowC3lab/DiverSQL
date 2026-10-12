WITH item_rank AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE
            WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_quantity), 0) > 100 THEN 'High'
            WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_quantity), 0) BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        RANK() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type, i.i_item_id, i.i_product_name
    HAVING SUM(cs.cs_quantity) > 0
)
SELECT
    sm_ship_mode_id,
    sm_type,
    i_item_id,
    i_product_name,
    total_net_profit,
    total_quantity,
    profit_category,
    profit_rank
FROM item_rank
WHERE profit_rank <= 5
ORDER BY sm_ship_mode_id, profit_rank
