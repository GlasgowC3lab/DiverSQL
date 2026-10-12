WITH daily_store_returns AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        hd_ret.hd_income_band_sk AS refunded_income_band,
        hd_ret.hd_vehicle_count AS refunded_vehicle_count,
        hd_ret_ret.hd_buy_potential AS returning_buy_potential,
        t.t_hour,
        t.t_am_pm,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_fee) AS total_fee,
        AVG(wr.wr_return_quantity) AS avg_quantity
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ret
        ON wr.wr_refunded_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ret_ret
        ON wr.wr_returning_hdemo_sk = hd_ret_ret.hd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        hd_ret.hd_income_band_sk,
        hd_ret.hd_vehicle_count,
        hd_ret_ret.hd_buy_potential,
        t.t_hour,
        t.t_am_pm
)
SELECT
    dsr.d_date,
    dsr.d_year,
    dsr.d_month_seq,
    dsr.s_store_name,
    dsr.refunded_income_band,
    dsr.refunded_vehicle_count,
    dsr.returning_buy_potential,
    dsr.t_hour,
    dsr.t_am_pm,
    dsr.return_count,
    dsr.total_return_amt,
    dsr.total_fee,
    dsr.avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY dsr.s_store_name ORDER BY dsr.total_return_amt DESC) AS store_rank
FROM daily_store_returns dsr
WHERE dsr.d_year BETWEEN 2000 AND 2002
ORDER BY dsr.total_return_amt DESC, dsr.d_date
LIMIT 200
