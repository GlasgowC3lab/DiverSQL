WITH sales_monthly AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        d_sales.d_year,
        d_sales.d_month_seq,
        SUM(cs.cs_quantity) AS month_sales_qty,
        COUNT(DISTINCT s.s_store_id) AS store_count
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN store s ON (s.s_closed_date_sk IS NULL OR cs.cs_sold_date_sk <= s.s_closed_date_sk)
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk, d_sales.d_year, d_sales.d_month_seq
),
inventory_monthly AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        d_inv.d_year,
        d_inv.d_month_seq,
        AVG(inv.inv_quantity_on_hand) AS avg_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk, d_inv.d_year, d_inv.d_month_seq
),
turnover_calculated AS (
    SELECT
        s.cs_item_sk,
        s.cs_warehouse_sk,
        s.d_year,
        s.d_month_seq,
        s.month_sales_qty,
        i.avg_on_hand,
        CASE 
            WHEN i.avg_on_hand > 0 THEN s.month_sales_qty / i.avg_on_hand
            ELSE NULL
        END AS turnover_ratio,
        s.store_count
    FROM sales_monthly s
    LEFT JOIN inventory_monthly i
        ON s.cs_item_sk = i.inv_item_sk
       AND s.cs_warehouse_sk = i.inv_warehouse_sk
       AND s.d_year = i.d_year
       AND s.d_month_seq = i.d_month_seq
)
SELECT
    cs_item_sk,
    cs_warehouse_sk,
    d_year,
    d_month_seq,
    turnover_ratio,
    CASE 
        WHEN turnover_ratio >= 2 THEN 'High'
        WHEN turnover_ratio >= 1 THEN 'Medium'
        WHEN turnover_ratio IS NOT NULL THEN 'Low'
        ELSE 'NoData'
    END AS turnover_category,
    store_count,
    DENSE_RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY turnover_ratio DESC) AS turnover_rank_month
FROM turnover_calculated
WHERE turnover_ratio IS NOT NULL
ORDER BY d_year, d_month_seq, turnover_rank_month
LIMIT 200
