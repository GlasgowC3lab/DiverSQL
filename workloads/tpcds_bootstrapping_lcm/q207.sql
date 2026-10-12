WITH store_monthly_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_state,
        s.s_market_id,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        SUM(wr.wr_return_tax) AS sum_return_tax,
        SUM(wr.wr_fee) AS sum_fee,
        SUM(wr.wr_net_loss) AS sum_net_loss,
        COUNT(*) AS returns_cnt,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        SUM(CASE WHEN d.d_weekend = 'Y' THEN wr.wr_return_amt ELSE 0.0 END) AS weekend_return_amt
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id, s.s_state, s.s_market_id
    HAVING COUNT(*) > 5
)
SELECT
    d_year,
    d_month_seq,
    s_store_id,
    s_state,
    s_market_id,
    sum_return_amt,
    sum_return_tax,
    sum_fee,
    sum_net_loss,
    returns_cnt,
    avg_return_qty,
    weekend_return_amt,
    LAG(sum_return_amt) OVER (PARTITION BY s_store_id ORDER BY d_year, d_month_seq) AS prev_month_return_amt,
    (sum_return_amt - LAG(sum_return_amt) OVER (PARTITION BY s_store_id ORDER BY d_year, d_month_seq)) AS return_amt_change,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY sum_return_amt DESC) AS store_year_rank
FROM store_monthly_returns
ORDER BY d_year, d_month_seq, sum_return_amt DESC
LIMIT 100
