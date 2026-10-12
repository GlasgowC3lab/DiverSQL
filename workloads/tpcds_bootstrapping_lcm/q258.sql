WITH aggregated AS (
    SELECT
        d.d_date_id,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        t.t_hour,
        t.t_shift,
        COUNT(*) AS return_transactions,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM date_dim d
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY
        d.d_date_id,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        t.t_hour,
        t.t_shift
)
SELECT
    a.d_date_id,
    a.d_year,
    a.d_month_seq,
    a.s_store_id,
    a.s_store_name,
    a.s_state,
    a.t_hour,
    a.t_shift,
    a.return_transactions,
    a.total_return_amount,
    a.total_return_tax,
    a.avg_return_quantity,
    CASE 
        WHEN a.total_return_tax = 0 THEN NULL
        ELSE a.total_return_amount / a.total_return_tax
    END AS amt_to_tax_ratio,
    SUM(a.total_return_amount) OVER (
        PARTITION BY a.s_state
        ORDER BY a.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_state_return_amount
FROM aggregated a
ORDER BY a.d_date, a.s_state, a.t_hour
LIMIT 100
