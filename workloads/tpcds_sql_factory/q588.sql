WITH cur_daily AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_return_amt_inc_tax) AS daily_return_amount,
        SUM(sr.sr_net_loss) AS daily_net_loss,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        d.d_same_day_ly AS prev_date_sk
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY d.d_date_sk, d.d_year, d.d_moy, d.d_same_day_ly
), prev_daily AS (
    SELECT
        d.d_date_sk,
        SUM(sr.sr_return_amt_inc_tax) AS prev_daily_return_amount,
        SUM(sr.sr_net_loss) AS prev_daily_net_loss,
        AVG(hd.hd_vehicle_count) AS prev_avg_vehicle_count
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY d.d_date_sk
), monthly_agg AS (
    SELECT
        cd.d_year,
        cd.d_moy AS month,
        SUM(cd.daily_return_amount) AS total_return_amount,
        SUM(pd.prev_daily_return_amount) AS total_prev_return_amount,
        SUM(cd.daily_net_loss) AS total_net_loss,
        SUM(pd.prev_daily_net_loss) AS total_prev_net_loss,
        CASE
            WHEN SUM(pd.prev_daily_return_amount) = 0 THEN NULL
            ELSE (SUM(cd.daily_return_amount) - SUM(pd.prev_daily_return_amount)) / SUM(pd.prev_daily_return_amount) * 100
        END AS growth_pct,
        CASE
            WHEN SUM(pd.prev_daily_return_amount) = 0 THEN 'No Prior Data'
            WHEN (SUM(cd.daily_return_amount) - SUM(pd.prev_daily_return_amount)) / SUM(pd.prev_daily_return_amount) * 100 > 20 THEN 'High Growth'
            WHEN (SUM(cd.daily_return_amount) - SUM(pd.prev_daily_return_amount)) / SUM(pd.prev_daily_return_amount) * 100 < -20 THEN 'Decline'
            ELSE 'Stable'
        END AS growth_category,
        AVG(cd.avg_vehicle_count) AS avg_vehicle_count_current_month
    FROM cur_daily cd
    LEFT JOIN prev_daily pd ON cd.prev_date_sk = pd.d_date_sk
    GROUP BY cd.d_year, cd.d_moy
    HAVING SUM(cd.daily_return_amount) > 0
)
SELECT
    d_year,
    month,
    total_return_amount,
    total_prev_return_amount,
    total_net_loss,
    total_prev_net_loss,
    growth_pct,
    growth_category,
    avg_vehicle_count_current_month,
    RANK() OVER (PARTITION BY d_year ORDER BY COALESCE(growth_pct, 0) DESC) AS month_growth_rank
FROM monthly_agg
ORDER BY d_year, month
