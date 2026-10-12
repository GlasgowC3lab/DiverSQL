WITH monthly_sales AS (
    SELECT
        d.d_year AS year,
        EXTRACT(MONTH FROM d.d_date) AS month,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
    GROUP BY d.d_year, EXTRACT(MONTH FROM d.d_date)
)
SELECT
    year,
    month,
    total_net_paid,
    total_net_profit,
    CASE WHEN total_net_paid = 0 THEN 0 ELSE total_net_profit / total_net_paid END AS profit_margin,
    LAG(total_net_paid) OVER (PARTITION BY year ORDER BY month) AS prev_month_net_paid,
    total_net_paid - LAG(total_net_paid) OVER (PARTITION BY year ORDER BY month) AS net_paid_change,
    CASE
        WHEN LAG(total_net_paid) OVER (PARTITION BY year ORDER BY month) = 0 THEN NULL
        ELSE (total_net_paid - LAG(total_net_paid) OVER (PARTITION BY year ORDER BY month)) /
             LAG(total_net_paid) OVER (PARTITION BY year ORDER BY month)
    END AS mom_growth_pct,
    SUM(total_net_paid) OVER (PARTITION BY year ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid
FROM monthly_sales
ORDER BY year, month
