WITH pre_agg_returns AS (
    SELECT
        wr_returned_date_sk,
        wr_returning_hdemo_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        COUNT(*) AS return_cnt,
        AVG(wr_return_ship_cost) AS avg_ship_cost
    FROM web_returns
    WHERE wr_return_amt_inc_tax > 500
    GROUP BY wr_returned_date_sk, wr_returning_hdemo_sk
)
SELECT
    d.d_date,
    d.d_year,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    r.total_return_amt_inc_tax,
    r.return_cnt,
    r.avg_ship_cost,
    ROW_NUMBER() OVER (ORDER BY d.d_date ASC) AS row_num,
    t.promo_flag
FROM pre_agg_returns r
JOIN date_dim d
    ON r.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON r.wr_returning_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN (VALUES (1), (2), (3)) AS t(promo_flag)
WHERE d.d_year = 2001
  AND ib.ib_upper_bound >= 100000
  AND hd.hd_vehicle_count >= 1
  AND d.d_date_sk NOT IN (
        SELECT wr_returned_date_sk
        FROM web_returns
        WHERE wr_return_quantity > 10
    )
ORDER BY d.d_date DESC, r.total_return_amt_inc_tax DESC
LIMIT 100
