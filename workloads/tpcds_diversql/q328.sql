WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
high_quantity_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Medium' END AS profit_category,
        (
            SELECT avg(cs2.cs_net_paid)
            FROM catalog_sales cs2
            WHERE cs2.cs_order_number = cs.cs_order_number
        ) AS avg_net_paid_per_order
    FROM sampled_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_quantity > 10
),
orders_with_returns AS (
    SELECT DISTINCT cr.cr_order_number AS cs_order_number
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    WHERE cr.cr_return_quantity > 0
)
SELECT
    hqs.cs_order_number,
    hqs.cs_item_sk,
    hqs.cs_net_profit,
    hqs.profit_category,
    hqs.avg_net_paid_per_order
FROM high_quantity_sales hqs
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = hqs.cs_item_sk
      AND sr.sr_return_quantity > 0
)
EXCEPT
SELECT
    owr.cs_order_number,
    NULL AS cs_item_sk,
    NULL AS cs_net_profit,
    NULL AS profit_category,
    NULL AS avg_net_paid_per_order
FROM orders_with_returns owr
ORDER BY cs_net_profit DESC
LIMIT 100
