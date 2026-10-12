WITH returns_by_date AS (
    SELECT
        wr.wr_returned_date_sk,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_tax) AS total_return_tax
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    rbd.num_returns,
    rbd.total_return_amt,
    rbd.total_net_loss,
    rbd.total_return_tax,
    ROUND(AVG(hd_ref.hd_vehicle_count * 1.0), 2) AS avg_refunded_vehicle_cnt,
    ROUND(AVG(hd_ret.hd_vehicle_count * 1.0), 2) AS avg_returning_vehicle_cnt,
    SUM(CASE WHEN d.d_weekend = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS weekend_return_amt
FROM returns_by_date rbd
JOIN date_dim d
    ON rbd.wr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
  AND s.s_state IN ('CA','TX','NY')
  AND hd_ref.hd_buy_potential = 'HIGH'
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    hd_ref.hd_buy_potential,
    hd_ret.hd_buy_potential,
    rbd.num_returns,
    rbd.total_return_amt,
    rbd.total_net_loss,
    rbd.total_return_tax
HAVING rbd.total_return_amt > 10000
ORDER BY rbd.total_return_amt DESC
LIMIT 100
