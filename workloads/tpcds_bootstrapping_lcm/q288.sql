SELECT
    cc.cc_division,
    s.s_state,
    ws.web_market_manager,
    d.d_year,
    d.d_quarter_name,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_fee) AS total_fee,
    COUNT(*) AS return_count,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_quantity * sr.sr_return_amt ELSE 0 END) AS weighted_return_amount,
    SUM(CASE WHEN ws.web_gmt_offset IS NOT NULL THEN ws.web_gmt_offset ELSE 0 END) AS total_web_gmt_offset,
    SUM(CASE WHEN cc.cc_tax_percentage IS NOT NULL THEN cc.cc_tax_percentage ELSE 0 END) AS total_cc_tax_percentage
FROM store_returns sr
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
    AND s.s_closed_date_sk = d.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    cc.cc_division,
    s.s_state,
    ws.web_market_manager,
    d.d_year,
    d.d_quarter_name
HAVING SUM(sr.sr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
