WITH ship_stats AS (
    SELECT
        d.d_year,
        d.d_week_seq,
        cs.cs_ship_mode_sk,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        AVG(cs.cs_ext_tax) AS avg_tax,
        SUM(cs.cs_net_paid_inc_ship_tax) AS sum_net_paid_inc_ship_tax,
        COUNT(*) AS txn_count,
        CASE
            WHEN AVG(cs.cs_ext_ship_cost) < 8 THEN 'Low'
            WHEN AVG(cs.cs_ext_ship_cost) BETWEEN 8 AND 25 THEN 'Medium'
            ELSE 'High'
        END AS ship_cost_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    WHERE d.d_week_seq % 2 = 0   -- only even weeks
    GROUP BY d.d_year, d.d_week_seq, cs.cs_ship_mode_sk
),
windowed_stats AS (
    SELECT
        d_year,
        d_week_seq,
        cs_ship_mode_sk,
        avg_ship_cost,
        avg_discount,
        avg_tax,
        sum_net_paid_inc_ship_tax,
        txn_count,
        ship_cost_category,
        SUM(sum_net_paid_inc_ship_tax) OVER (PARTITION BY d_year ORDER BY d_week_seq) AS cumulative_net_paid,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY avg_ship_cost DESC) AS cost_rank
    FROM ship_stats
)
SELECT
    d_year,
    d_week_seq,
    cs_ship_mode_sk,
    ROUND(avg_ship_cost, 2) AS avg_ship_cost,
    ROUND(avg_discount, 2) AS avg_discount,
    ROUND(avg_tax, 2) AS avg_tax,
    ROUND(sum_net_paid_inc_ship_tax, 2) AS sum_net_paid_inc_ship_tax,
    txn_count,
    ship_cost_category,
    ROUND(cumulative_net_paid, 2) AS cumulative_net_paid,
    cost_rank
FROM windowed_stats
WHERE cost_rank <= 5
ORDER BY d_year, cost_rank, d_week_seq
