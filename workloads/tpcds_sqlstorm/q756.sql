WITH
sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        d.d_date,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        COALESCE(cs.cs_ext_discount_amt, 0) AS discount_amt,
        CASE
            WHEN cs.cs_quantity >= 20 THEN 'HIGH'
            WHEN cs.cs_quantity BETWEEN 10 AND 19 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS qty_category,
        (cs.cs_net_paid - COALESCE(cs.cs_ext_discount_amt, 0)) / NULLIF(cs.cs_quantity, 0) AS avg_price_per_item,
        CONCAT('Item_', CAST(cs.cs_item_sk AS VARCHAR)) AS item_label,
        cc.cc_name AS call_center_name,
        cc.cc_gmt_offset
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_sold_date_sk BETWEEN
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2000)
        AND
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2002)
),
returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        d.d_date AS return_date,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_return_quantity > 0
),
sales_returns AS (
    SELECT
        s.cs_item_sk,
        s.cs_order_number,
        s.d_date,
        s.qty_category,
        s.avg_price_per_item,
        COALESCE(r.cr_return_quantity, 0) AS return_quantity,
        s.cs_net_paid - COALESCE(r.cr_return_amount, 0) AS net_sales_adj,
        s.cs_net_profit - COALESCE(r.cr_net_loss, 0) AS net_profit_adj,
        s.call_center_name,
        s.cc_gmt_offset,
        ROW_NUMBER() OVER (PARTITION BY s.cs_item_sk ORDER BY s.cs_net_paid DESC) AS rn_item,
        ROW_NUMBER() OVER (ORDER BY s.cs_net_paid - COALESCE(r.cr_return_amount, 0) DESC) AS rn_global
    FROM sales s
    LEFT JOIN returns r
        ON s.cs_item_sk = r.cr_item_sk
        AND s.d_date = r.return_date
    WHERE (s.cs_net_paid - COALESCE(r.cr_return_amount, 0)) > 0
),
orphan_sales AS (
    SELECT
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_order_number AS cs_order_number,
        d.d_date AS d_date,
        CASE
            WHEN cs.cs_quantity >= 20 THEN 'HIGH'
            WHEN cs.cs_quantity BETWEEN 10 AND 19 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS qty_category,
        (cs.cs_net_paid - COALESCE(cs.cs_ext_discount_amt, 0)) / NULLIF(cs.cs_quantity, 0) AS avg_price_per_item,
        0 AS return_quantity,
        cs.cs_net_paid AS net_sales_adj,
        cs.cs_net_profit AS net_profit_adj,
        cc.cc_name AS call_center_name,
        cc.cc_gmt_offset,
        NULL AS rn_item,
        ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC) AS rn_global
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM returns r
        WHERE r.cr_item_sk = cs.cs_item_sk
          AND r.return_date = d.d_date
          AND r.cr_return_quantity > 0
    )
)
SELECT
    t.cs_item_sk,
    t.cs_order_number,
    t.d_date,
    t.qty_category,
    t.avg_price_per_item,
    t.return_quantity,
    t.net_sales_adj,
    t.net_profit_adj,
    t.call_center_name,
    t.cc_gmt_offset,
    t.rn_item,
    t.rn_global,
    (SELECT MAX(i_current_price) FROM item i WHERE i.i_item_sk = t.cs_item_sk) AS max_item_price,
    (SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = t.cs_item_sk) AS avg_item_net_paid,
    CONCAT('Profit_', CAST(ROUND(t.net_profit_adj, 2) AS VARCHAR)) AS profit_label
FROM (
    SELECT * FROM sales_returns
    UNION ALL
    SELECT * FROM orphan_sales
) t
WHERE t.rn_global <= 10
ORDER BY t.net_sales_adj DESC
LIMIT 10
