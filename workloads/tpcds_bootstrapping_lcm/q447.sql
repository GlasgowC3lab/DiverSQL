WITH aggregated_returns AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        s.s_state,
        s.s_city,
        dr_return.d_year AS return_year,
        dr_return.d_month_seq AS return_month,
        dr_return.d_quarter_seq AS return_quarter,
        t.t_hour,
        t.t_meal_time,
        dr_end.d_year AS catalog_end_year,
        dr_end.d_month_seq AS catalog_end_month,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN date_dim dr_return
        ON wr.wr_returned_date_sk = dr_return.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN store s
        ON s.s_closed_date_sk = dr_return.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = dr_return.d_date_sk
    JOIN date_dim dr_end
        ON cp.cp_end_date_sk = dr_end.d_date_sk
    WHERE dr_return.d_year >= 2020
    GROUP BY
        cp.cp_department,
        cp.cp_type,
        s.s_state,
        s.s_city,
        dr_return.d_year,
        dr_return.d_month_seq,
        dr_return.d_quarter_seq,
        t.t_hour,
        t.t_meal_time,
        dr_end.d_year,
        dr_end.d_month_seq
)
SELECT
    ar.cp_department,
    ar.cp_type,
    ar.s_state,
    ar.s_city,
    ar.return_year,
    ar.return_month,
    ar.return_quarter,
    ar.t_hour,
    ar.t_meal_time,
    ar.catalog_end_year,
    ar.catalog_end_month,
    ar.return_count,
    ar.total_return_amt,
    ar.total_return_tax,
    ar.total_fee,
    ar.total_net_loss,
    ar.avg_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY ar.cp_department ORDER BY ar.total_return_amt DESC) AS dept_rank_by_return_amt,
    RANK() OVER (ORDER BY ar.total_net_loss DESC) AS overall_net_loss_rank
FROM aggregated_returns ar
WHERE ar.total_return_amt > 1000
ORDER BY ar.total_return_amt DESC
LIMIT 100
