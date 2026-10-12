WITH shift_returns AS (
    SELECT
        t.t_shift,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_return_tax) AS total_return_tax,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN promotion p
        ON sr.sr_item_sk = p.p_item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_holiday = 'Christmas'
      AND d.d_weekend = 'Y'
      AND p.p_discount_active = 'Y'
    GROUP BY t.t_shift
)
SELECT
    t_shift,
    total_return_amt,
    avg_return_qty,
    total_return_tax,
    distinct_customers,
    RANK() OVER (ORDER BY total_return_amt DESC) AS shift_rank
FROM shift_returns
ORDER BY total_return_amt DESC
LIMIT 10
