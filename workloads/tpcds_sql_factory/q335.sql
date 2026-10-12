WITH monthly_aggregates AS (
    SELECT
        c.c_birth_month,
        SUM(sr.sr_return_quantity) AS total_quantity,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        AVG(ib.ib_lower_bound) AS avg_income_lower_bound
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY c.c_birth_month
)
SELECT
    c_birth_month,
    total_quantity,
    avg_net_loss,
    avg_income_lower_bound,
    LAG(total_quantity) OVER (ORDER BY c_birth_month) AS prev_quantity,
    CASE 
        WHEN LAG(total_quantity) OVER (ORDER BY c_birth_month) IS NULL THEN NULL
        ELSE (total_quantity - LAG(total_quantity) OVER (ORDER BY c_birth_month)) / NULLIF(LAG(total_quantity) OVER (ORDER BY c_birth_month), 0)
    END AS pct_change_quantity,
    CASE WHEN total_quantity > 500 THEN 'Peak' ELSE 'Normal' END AS month_category
FROM monthly_aggregates
ORDER BY c_birth_month
