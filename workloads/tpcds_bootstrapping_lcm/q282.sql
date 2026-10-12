SELECT
    cc.cc_name,
    cc.cc_manager,
    cc.cc_city,
    cc.cc_tax_percentage,
    d.d_date,
    d.d_year,
    d.d_quarter_name,
    s.s_store_name,
    s.s_city,
    s.s_floor_space,
    s.s_tax_percentage,
    sr.sr_ticket_number,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    (sr.sr_return_amt * (1 + cc.cc_tax_percentage / 100)) AS adjusted_return_amt,
    ws.web_name,
    ws.web_city,
    ws.web_market_manager,
    ws.web_tax_percentage
FROM call_center cc
JOIN date_dim d
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
WHERE cc.cc_tax_percentage > 5
  AND s.s_floor_space > 5000
  AND ws.web_tax_percentage < 10
  AND d.d_year = 2022
  AND sr.sr_return_quantity > 0
ORDER BY d.d_date DESC
LIMIT 100
