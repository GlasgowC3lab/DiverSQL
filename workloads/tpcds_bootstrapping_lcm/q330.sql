SELECT
    cc.cc_name,
    s.s_store_name,
    dd_closed.d_year,
    dd_closed.d_quarter_name,
    ws.web_name,
    SUM(inv.inv_quantity_on_hand) AS total_quantity,
    date_diff('day', dd_open.d_date, dd_closed.d_date) AS days_open
FROM call_center cc
JOIN date_dim dd_open
    ON cc.cc_open_date_sk = dd_open.d_date_sk
JOIN date_dim dd_closed
    ON cc.cc_closed_date_sk = dd_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_closed.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = dd_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = dd_open.d_date_sk
   AND ws.web_close_date_sk = dd_closed.d_date_sk
WHERE dd_closed.d_year BETWEEN 2000 AND 2005
  AND inv.inv_quantity_on_hand > 0
GROUP BY
    cc.cc_name,
    s.s_store_name,
    dd_closed.d_year,
    dd_closed.d_quarter_name,
    ws.web_name,
    dd_open.d_date,
    dd_closed.d_date
HAVING SUM(inv.inv_quantity_on_hand) > 1000
ORDER BY total_quantity DESC
LIMIT 100
