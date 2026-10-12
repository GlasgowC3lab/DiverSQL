WITH agg AS (
    SELECT
        dr.d_date AS return_date,
        dr.d_day_name AS return_day_name,
        dr.d_week_seq AS week_seq,
        t.t_time AS return_time,
        t.t_shift AS time_shift,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        s.s_market_manager AS market_manager,
        hd_ret.hd_income_band_sk AS returning_income_band,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        SUM(wr.wr_fee) AS total_fee
    FROM web_returns wr
    JOIN date_dim dr
      ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN store s
      ON s.s_closed_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2022
    GROUP BY
        dr.d_date,
        dr.d_day_name,
        dr.d_week_seq,
        t.t_time,
        t.t_shift,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_manager,
        hd_ret.hd_income_band_sk,
        hd_ref.hd_income_band_sk
)
SELECT
    return_date,
    return_day_name,
    week_seq,
    return_time,
    time_shift,
    store_name,
    store_city,
    store_state,
    market_manager,
    returning_income_band,
    refunded_income_band,
    num_returns,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    total_fee,
    ROW_NUMBER() OVER (PARTITION BY return_date ORDER BY total_return_amount DESC) AS rank_by_return_amount
FROM agg
ORDER BY return_date, total_return_amount DESC
LIMIT 100
