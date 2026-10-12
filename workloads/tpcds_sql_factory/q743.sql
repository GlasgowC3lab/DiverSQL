SELECT
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    d.d_year,
    d.d_quarter_name,
    COUNT(*) AS total_returns,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(wr.wr_fee) > 0 THEN SUM(wr.wr_net_loss) / SUM(wr.wr_fee)
        ELSE NULL
    END AS loss_per_fee_ratio,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(wr.wr_net_loss) DESC) AS yearly_loss_rank
FROM store s
JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2023
GROUP BY s.s_store_id, s.s_store_name, ws.web_site_id, ws.web_name, d.d_year, d.d_quarter_name
HAVING COUNT(*) >= 5
ORDER BY yearly_loss_rank
