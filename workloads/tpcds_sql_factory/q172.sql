WITH monthly_sales AS (
    SELECT
        cs.cs_item_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_year, d.d_month_seq
),
monthly_inventory AS (
    SELECT
        i.inv_item_sk,
        d.d_year,
        d.d_month_seq,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    GROUP BY i.inv_item_sk, d.d_year, d.d_month_seq
),
monthly_turnover AS (
    SELECT
        s.cs_item_sk AS item_sk,
        s.d_year,
        s.d_month_seq,
        s.total_quantity_sold,
        i.avg_inventory_qty,
        CASE
            WHEN i.avg_inventory_qty = 0 THEN NULL
            ELSE s.total_quantity_sold / i.avg_inventory_qty
        END AS turnover_ratio
    FROM monthly_sales s
    LEFT JOIN monthly_inventory i
        ON s.cs_item_sk = i.inv_item_sk
        AND s.d_year = i.d_year
        AND s.d_month_seq = i.d_month_seq
),
ranked_turnover AS (
    SELECT
        item_sk,
        d_year,
        d_month_seq,
        total_quantity_sold,
        avg_inventory_qty,
        turnover_ratio,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY turnover_ratio DESC) AS turnover_rank
    FROM monthly_turnover
)
SELECT
    d_year,
    d_month_seq,
    item_sk,
    total_quantity_sold,
    avg_inventory_qty,
    ROUND(turnover_ratio, 4) AS turnover_ratio,
    turnover_rank
FROM ranked_turnover
WHERE turnover_rank <= 10
ORDER BY d_year, d_month_seq, turnover_rank
