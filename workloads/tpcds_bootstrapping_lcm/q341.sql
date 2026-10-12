WITH returns_by_store AS (
    SELECT 
        d.d_year,
        d.d_current_month,
        d.d_quarter_name,
        s.s_store_sk,
        s.s_state,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_net_loss) AS avg_net_loss
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2021
    GROUP BY d.d_year, d.d_current_month, d.d_quarter_name, s.s_store_sk, s.s_state
)
SELECT 
    rbs.d_year,
    rbs.d_current_month,
    rbs.d_quarter_name,
    rbs.s_state,
    rbs.s_store_sk,
    rbs.total_return_amt,
    rbs.return_cnt,
    rbs.avg_net_loss,
    RANK() OVER (PARTITION BY rbs.d_year ORDER BY rbs.total_return_amt DESC) AS store_return_rank
FROM returns_by_store rbs
WHERE rbs.return_cnt > 5
ORDER BY rbs.d_year, rbs.d_current_month, store_return_rank
LIMIT 100
