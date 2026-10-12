SELECT
    d.d_date,
    s.s_store_id,
    wsite.web_site_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(ws.ws_net_profit) AS web_net_profit,
    (SUM(ss.ss_ext_sales_price) - SUM(ws.ws_ext_sales_price)) AS sales_amount_diff
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN date_dim d_web_open
    ON wsite.web_open_date_sk = d_web_open.d_date_sk
LEFT JOIN date_dim d_web_close
    ON wsite.web_close_date_sk = d_web_close.d_date_sk
JOIN date_dim d_ship_date
    ON ws.ws_ship_date_sk = d_ship_date.d_date_sk
WHERE (s.s_closed_date_sk IS NULL OR d.d_date_sk < s.s_closed_date_sk)
  AND (wsite.web_close_date_sk IS NULL OR d.d_date_sk < wsite.web_close_date_sk)
  AND d.d_date_sk >= wsite.web_open_date_sk
  AND d.d_year = 2022
GROUP BY d.d_date, s.s_store_id, wsite.web_site_id
ORDER BY d.d_date DESC, s.s_store_id
LIMIT 100
