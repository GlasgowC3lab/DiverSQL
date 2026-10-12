WITH recent_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    warehouse_name,
    record_type,
    total_amount
FROM (
    -- Sales side (records with sales information)
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'sale' AS record_type,
        SUM(cs.cs_net_paid) AS total_amount
    FROM (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ) cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    RIGHT OUTER JOIN recent_dates rd
        ON cs.cs_sold_date_sk = rd.d_date_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT p.p_promo_id
        FROM promotion p
        WHERE p.p_item_sk = cs.cs_item_sk
          AND p.p_start_date_sk <= cs.cs_sold_date_sk
          AND p.p_end_date_sk >= cs.cs_sold_date_sk
        ORDER BY p.p_start_date_sk DESC
        LIMIT 1
    ) promo ON TRUE
    WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = cs.cs_item_sk
    )
    GROUP BY w.w_warehouse_name

    UNION ALL

    -- Returns side (records with return information)
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'return' AS record_type,
        SUM(cr.cr_net_loss) AS total_amount
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
        ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT r.r_reason_desc
        FROM reason r
        WHERE r.r_reason_sk = cr.cr_reason_sk
    ) reason_desc ON TRUE
    WHERE cr.cr_return_quantity > 0
    GROUP BY w.w_warehouse_name
) combined
ORDER BY total_amount DESC
LIMIT 100
