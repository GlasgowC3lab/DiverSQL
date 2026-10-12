SELECT
    d.d_date AS return_date,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    COUNT(DISTINCT s.s_store_sk) AS closed_store_cnt,
    COUNT(DISTINCT ws_open.web_site_sk) AS opened_web_site_cnt,
    COUNT(DISTINCT ws_close.web_site_sk) AS closed_web_site_cnt,
    SUM(cr.cr_return_quantity) AS catalog_return_qty,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
    AVG(wr.wr_return_amt) AS avg_web_return_amount,
    CASE
        WHEN SUM(wr.wr_net_loss) = 0 THEN NULL
        ELSE SUM(cr.cr_net_loss) / SUM(wr.wr_net_loss)
    END AS catalog_to_web_loss_ratio
FROM
    date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_open ON ws_open.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_close ON ws_close.web_close_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq
HAVING
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0
ORDER BY
    d.d_date DESC
LIMIT 100
