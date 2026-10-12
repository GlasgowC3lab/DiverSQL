WITH hd_income AS (
    SELECT DISTINCT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN hd.hd_vehicle_count > 2 THEN 'Multi'
            ELSE 'Few'
        END AS vehicle_category,
        split(hd.hd_buy_potential, ',') AS buy_pot_arr
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(hd.hd_buy_potential, 'HIGH|MEDIUM')
)
SELECT
    t.t_time_id,
    substring(t.t_time_id, 1, 5) AS time_prefix,
    hd_income.vehicle_category,
    pot_token,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_amt_inc_tax) AS avg_return_inc_tax,
    CASE 
        WHEN SUM(wr.wr_return_amt) > 1000 THEN 'HighLoss'
        ELSE 'LowLoss'
    END AS loss_category
FROM hd_income
JOIN web_returns wr
    ON wr.wr_refunded_hdemo_sk = hd_income.hd_demo_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
CROSS JOIN UNNEST(hd_income.buy_pot_arr) AS u(pot_token)
WHERE t.t_time_id LIKE 'AAAAAAA%'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
          AND wr2.wr_return_amt > 50
    )
GROUP BY
    t.t_time_id,
    substring(t.t_time_id, 1, 5),
    hd_income.vehicle_category,
    pot_token
ORDER BY total_return_amt DESC, t.t_time_id ASC
LIMIT 100
