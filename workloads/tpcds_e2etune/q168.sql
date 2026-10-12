SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    COUNT(DISTINCT ws_open.web_site_sk) AS sites_opened_on_return_day,
    COUNT(DISTINCT ws_close.web_site_sk) AS sites_closed_on_return_day
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_site ws_open ON ws_open.web_open_date_sk = d.d_date_sk
LEFT JOIN web_site ws_close ON ws_close.web_close_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cr.cr_return_amount > 0
GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
