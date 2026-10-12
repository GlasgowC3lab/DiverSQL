WITH store_quarter_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_quarter_name,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(CASE WHEN d.d_holiday = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS holiday_return_amount
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_quarter_name
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    sqr.s_store_id,
    sqr.s_store_name,
    sqr.d_year,
    sqr.d_quarter_name,
    sqr.return_count,
    sqr.total_return_amount,
    sqr.total_net_loss,
    sqr.holiday_return_amount,
    RANK() OVER (PARTITION BY sqr.d_year ORDER BY sqr.total_net_loss DESC) AS loss_rank_within_year
FROM store_quarter_returns sqr
ORDER BY sqr.d_year, loss_rank_within_year
