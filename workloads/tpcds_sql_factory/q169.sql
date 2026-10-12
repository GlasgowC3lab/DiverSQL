WITH ship_stats AS (
    SELECT
        d.d_year,
        d.d_week_seq,
        cs.cs_ship_mode_sk,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        AVG(cs.cs_ext_tax) AS avg_tax,
        AVG(cs.cs_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax,
        CASE
            WHEN AVG(cs.cs_ext_ship_cost) < 10 THEN 'Low'
            WHEN AVG(cs.cs_ext_ship_cost) BETWEEN 10 AND 30 THEN 'Medium'
            ELSE 'High'
        END AS ship_cost_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    LEFT JOIN web_site w ON w.web_open_date_sk <= cs.cs_ship_date_sk
        AND (w.web_close_date_sk IS NULL OR w.web_close_date_sk >= cs.cs_ship_date_sk)
    GROUP BY d.d_year, d.d_week_seq, cs.cs_ship_mode_sk
),
ranked_ship_stats AS (
    SELECT
        d_year,
        d_week_seq,
        cs_ship_mode_sk,
        avg_ship_cost,
        avg_discount,
        avg_tax,
        avg_net_paid_inc_ship_tax,
        ship_cost_category,
        DENSE_RANK() OVER (PARTITION BY d_year, d_week_seq ORDER BY avg_net_paid_inc_ship_tax DESC) AS mode_rank
    FROM ship_stats
)
SELECT
    d_year,
    d_week_seq,
    cs_ship_mode_sk,
    ROUND(avg_ship_cost, 2) AS avg_ship_cost,
    ROUND(avg_discount, 2) AS avg_discount,
    ROUND(avg_tax, 2) AS avg_tax,
    ROUND(avg_net_paid_inc_ship_tax, 2) AS avg_net_paid_inc_ship_tax,
    ship_cost_category,
    mode_rank
FROM ranked_ship_stats
WHERE mode_rank <= 3
ORDER BY d_year, d_week_seq, mode_rank
