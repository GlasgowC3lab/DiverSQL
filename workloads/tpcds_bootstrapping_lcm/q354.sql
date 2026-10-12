WITH sr_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_store_sk AS store_sk,
        SUM(sr.sr_return_amt) AS store_return_total,
        SUM(sr.sr_return_tax) AS store_return_tax_total,
        SUM(sr.sr_net_loss) AS store_net_loss_total
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_return_amt) AS web_return_total,
        SUM(wr.wr_return_tax) AS web_return_tax_total,
        SUM(wr.wr_net_loss) AS web_net_loss_total
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_quarter_name,
    s.s_store_name,
    s.s_state,
    sr_agg.store_return_total,
    sr_agg.store_return_tax_total,
    sr_agg.store_net_loss_total,
    wr_agg.web_return_total,
    wr_agg.web_return_tax_total,
    wr_agg.web_net_loss_total,
    ws.web_name,
    ws.web_state,
    ws.web_market_manager,
    COALESCE(sr_agg.store_return_total, 0) - COALESCE(wr_agg.web_return_total, 0) AS net_return_amount_diff,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY d.d_date DESC) AS store_return_rank
FROM date_dim d
JOIN sr_agg ON sr_agg.date_sk = d.d_date_sk
JOIN store s ON sr_agg.store_sk = s.s_store_sk
LEFT JOIN wr_agg ON wr_agg.date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND ws.web_state = 'CA'
ORDER BY net_return_amount_diff DESC
LIMIT 100
