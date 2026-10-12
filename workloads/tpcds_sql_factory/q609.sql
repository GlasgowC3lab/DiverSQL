WITH daily_sales AS (
    SELECT
        d.d_date,
        s.s_store_id,
        SUM(cs.cs_net_paid) AS daily_net_paid,
        CASE WHEN d.d_dow IN (6,7) THEN 'Weekend' ELSE 'Weekday' END AS day_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store s ON (s.s_closed_date_sk IS NULL OR d.d_date_sk <= s.s_closed_date_sk)
    GROUP BY d.d_date, s.s_store_id, d.d_dow
),
 daily_inventory AS (
    SELECT
        d.d_date,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT
    ds.d_date,
    ds.s_store_id,
    ds.day_type,
    ds.daily_net_paid,
    di.total_inventory_qty,
    SUM(ds.daily_net_paid) OVER (PARTITION BY ds.s_store_id ORDER BY ds.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
    RANK() OVER (PARTITION BY ds.s_store_id ORDER BY ds.daily_net_paid DESC) AS daily_sales_rank
FROM daily_sales ds
LEFT JOIN daily_inventory di ON ds.d_date = di.d_date
WHERE ds.daily_net_paid > 0
ORDER BY ds.s_store_id, ds.d_date
