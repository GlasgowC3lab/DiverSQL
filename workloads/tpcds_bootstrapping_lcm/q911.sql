WITH return_agg AS (
    SELECT
        d_ret.d_date AS return_date,
        d_ret.d_year,
        d_ret.d_current_month,
        d_ret.d_day_name,
        t.t_hour,
        t.t_meal_time,
        r.r_reason_desc,
        s.s_store_name,
        s.s_city,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 2020 AND 2022
    GROUP BY
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_current_month,
        d_ret.d_day_name,
        t.t_hour,
        t.t_meal_time,
        r.r_reason_desc,
        s.s_store_name,
        s.s_city
)
SELECT
    ra.return_date,
    ra.d_year,
    ra.d_current_month,
    ra.d_day_name,
    ra.t_hour,
    ra.t_meal_time,
    ra.r_reason_desc,
    ra.s_store_name,
    ra.s_city,
    ra.total_return_amt,
    ra.total_return_amt_inc_tax,
    ra.total_net_loss,
    ra.avg_return_qty,
    ra.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY ra.r_reason_desc ORDER BY ra.total_net_loss DESC) AS loss_rank
FROM return_agg ra
ORDER BY ra.total_net_loss DESC
LIMIT 100
