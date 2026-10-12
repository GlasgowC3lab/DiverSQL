WITH refund_stats AS (
    SELECT
        hd.hd_demo_sk AS hd_demo_sk,
        ib.ib_income_band_sk AS ib_income_band_sk,
        ib.ib_upper_bound AS ib_upper_bound,
        hd.hd_buy_potential AS hd_buy_potential,
        COUNT(wr.wr_order_number) AS returns_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_ship_cost) AS avg_ship_cost
    FROM web_returns wr
    FULL OUTER JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential IN ('0-500', '>10000')
      AND hd.hd_vehicle_count >= 0
      AND ib.ib_upper_bound <= 150000
      AND wr.wr_return_ship_cost > 100
    GROUP BY ROLLUP (hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_upper_bound, hd.hd_buy_potential)
)
SELECT
    hd_demo_sk,
    ib_income_band_sk,
    ib_upper_bound,
    hd_buy_potential,
    returns_cnt,
    total_return_amt,
    avg_ship_cost
FROM refund_stats rs
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_returning_hdemo_sk = rs.hd_demo_sk
)
ORDER BY total_return_amt DESC NULLS LAST, hd_demo_sk
LIMIT 100
