WITH daily_totals AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        d.d_weekend,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(CASE WHEN r.r_reason_desc = 'Customer Not Satisfied' THEN sr.sr_return_amt_inc_tax ELSE 0 END) AS amount_not_satisfied,
        DENSE_RANK() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS day_rank_in_month
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY d.d_date, d.d_year, d.d_month_seq, d.d_day_name, d.d_weekend
)
SELECT
    d_date,
    d_year,
    d_month_seq,
    d_day_name,
    d_weekend,
    total_return_amount,
    amount_not_satisfied,
    day_rank_in_month
FROM daily_totals
WHERE day_rank_in_month <= 5
ORDER BY d_year, d_month_seq, day_rank_in_month
