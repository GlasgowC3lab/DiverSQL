WITH returns_summary AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        s.s_state,
        ib_ref.ib_lower_bound AS refunded_income_lower,
        ib_ref.ib_upper_bound AS refunded_income_upper,
        ib_ret.ib_lower_bound AS returning_income_lower,
        ib_ret.ib_upper_bound AS returning_income_upper,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS total_returns,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(COALESCE(wr.wr_fee, 0)) AS total_fees,
        AVG(COALESCE(hd_ref.hd_vehicle_count, 0)) AS avg_vehicle_cnt_refunded,
        AVG(COALESCE(hd_ret.hd_vehicle_count, 0)) AS avg_vehicle_cnt_returning
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    LEFT JOIN income_band ib_ret ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state IN ('CA', 'NY')
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        s.s_state,
        ib_ref.ib_lower_bound,
        ib_ref.ib_upper_bound,
        ib_ret.ib_lower_bound,
        ib_ret.ib_upper_bound
)
SELECT
    rs.d_year,
    rs.d_quarter_name,
    rs.s_state,
    rs.refunded_income_lower,
    rs.refunded_income_upper,
    rs.returning_income_lower,
    rs.returning_income_upper,
    rs.total_return_amount,
    rs.total_returns,
    rs.avg_net_loss,
    rs.total_fees,
    rs.avg_vehicle_cnt_refunded,
    rs.avg_vehicle_cnt_returning,
    ROW_NUMBER() OVER (PARTITION BY rs.s_state ORDER BY rs.total_return_amount DESC) AS state_rank
FROM returns_summary rs
ORDER BY rs.total_return_amount DESC
LIMIT 100
