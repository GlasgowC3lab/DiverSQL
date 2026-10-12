WITH returns_by_quarter AS (
    SELECT
        d.d_year AS year,
        d.d_fy_quarter_seq AS fy_quarter_seq,
        d.d_quarter_seq AS quarter_seq,
        d.d_weekend AS weekend_flag,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM
        web_returns wr
    JOIN
        date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2005
        AND d.d_weekend = 'Y'
    GROUP BY
        d.d_year,
        d.d_fy_quarter_seq,
        d.d_quarter_seq,
        d.d_weekend
)
SELECT
    year,
    fy_quarter_seq,
    quarter_seq,
    total_return_amt,
    total_net_loss,
    cnt_returns,
    avg_return_qty,
    LAG(total_return_amt) OVER (PARTITION BY year ORDER BY fy_quarter_seq) AS prev_quarter_return_amt,
    (total_return_amt - LAG(total_return_amt) OVER (PARTITION BY year ORDER BY fy_quarter_seq))
        / NULLIF(LAG(total_return_amt) OVER (PARTITION BY year ORDER BY fy_quarter_seq), 0) AS qoq_growth
FROM
    returns_by_quarter
WHERE
    cnt_returns > 10
ORDER BY
    total_return_amt DESC
LIMIT 50
