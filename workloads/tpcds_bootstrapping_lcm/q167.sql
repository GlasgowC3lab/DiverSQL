SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    w.web_name,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    CASE 
        WHEN SUM(ss.ss_net_profit) = 0 THEN NULL
        ELSE SUM(ws.ws_net_profit) / SUM(ss.ss_net_profit)
    END AS web_to_store_profit_ratio,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
    MIN(d_closure.d_date) AS store_closure_date,
    MIN(d_open.d_date) AS web_site_open_date,
    MAX(d_close.d_date) AS web_site_close_date
FROM date_dim AS d
JOIN store_sales AS ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store AS s
    ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales AS ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site AS w
    ON ws.ws_web_site_sk = w.web_site_sk
LEFT JOIN date_dim AS d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
LEFT JOIN date_dim AS d_open
    ON w.web_open_date_sk = d_open.d_date_sk
LEFT JOIN date_dim AS d_close
    ON w.web_close_date_sk = d_close.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
GROUP BY d.d_year, d.d_month_seq, s.s_store_name, w.web_name
ORDER BY d.d_year, d.d_month_seq, s.s_store_name, w.web_name
LIMIT 100
