WITH agg AS (
    SELECT
        ib_r.ib_lower_bound AS income_lower,
        ib_r.ib_upper_bound AS income_upper,
        rhd.hd_vehicle_count AS hd_vehicle_count,
        AVG(fhd.hd_dep_count) AS avg_refunded_dep_count,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_return_quantity) AS total_quantity
    FROM web_returns wr
    JOIN household_demographics rhd
        ON wr.wr_returning_hdemo_sk = rhd.hd_demo_sk
    JOIN household_demographics fhd
        ON wr.wr_refunded_hdemo_sk = fhd.hd_demo_sk
    JOIN income_band ib_r
        ON rhd.hd_income_band_sk = ib_r.ib_income_band_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2450300
      AND rhd.hd_buy_potential IN ('501-1000', '1001-5000')
    GROUP BY ib_r.ib_lower_bound, ib_r.ib_upper_bound, rhd.hd_vehicle_count
)
SELECT
    income_lower,
    income_upper,
    hd_vehicle_count,
    avg_refunded_dep_count,
    return_cnt,
    total_net_loss,
    avg_return_amt,
    total_quantity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
