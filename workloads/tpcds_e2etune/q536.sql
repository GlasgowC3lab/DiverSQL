WITH base AS (
    SELECT
        i.i_brand,
        i.i_category,
        i.i_color,
        sm.sm_carrier,
        t.t_hour,
        COUNT(*) AS item_cnt,
        SUM(i.i_current_price) AS total_revenue,
        SUM(i.i_wholesale_cost) AS total_wholesale,
        AVG(i.i_current_price) AS avg_price,
        MAX(i.i_rec_start_date) AS max_start_date
    FROM
        item i
        LEFT JOIN ship_mode sm ON i.i_brand = sm.sm_carrier
        LEFT JOIN time_dim t ON t.t_hour = (i.i_item_sk % 24)
    WHERE
        i.i_current_price BETWEEN 1.0 AND 30.0
        AND i.i_color IN ('red', 'spring', 'rosy')
        AND t.t_hour IS NOT NULL
    GROUP BY
        i.i_brand,
        i.i_category,
        i.i_color,
        sm.sm_carrier,
        t.t_hour
),
ranked AS (
    SELECT
        i_brand,
        i_category,
        i_color,
        sm_carrier,
        t_hour,
        item_cnt,
        total_revenue,
        total_wholesale,
        avg_price,
        max_start_date,
        RANK() OVER (PARTITION BY i_brand ORDER BY total_wholesale DESC) AS wholesale_rank
    FROM base
)
SELECT
    i_brand,
    i_category,
    i_color,
    sm_carrier,
    t_hour,
    item_cnt,
    total_revenue,
    total_wholesale,
    avg_price,
    wholesale_rank
FROM ranked
WHERE wholesale_rank <= 5
ORDER BY i_brand, wholesale_rank, t_hour
