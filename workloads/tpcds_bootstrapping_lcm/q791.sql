WITH returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        COUNT(*) AS cnt_returns,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        SUM(wr.wr_net_loss) AS sum_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_cl.d_date AS site_close_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_state,
    r.cnt_returns,
    r.sum_return_amt,
    r.sum_net_loss,
    r.avg_return_qty,
    SUM(r.sum_return_amt) OVER (PARTITION BY s.s_store_id ORDER BY d_ret.d_date) AS cumulative_return_amt,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d_ret.d_date DESC) AS rn_recent_returns
FROM returns_agg r
JOIN date_dim d_ret ON r.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_cl ON ws.web_close_date_sk = d_cl.d_date_sk
WHERE d_ret.d_year = 2021
  AND s.s_state = 'CA'
  AND ws.web_state = 'CA'
ORDER BY r.sum_return_amt DESC
LIMIT 100
