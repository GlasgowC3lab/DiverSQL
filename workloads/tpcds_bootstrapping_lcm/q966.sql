SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_quarter_name AS sale_quarter,
    (d_sold.d_year * 100 + d_sold.d_month_seq) AS year_month_key,
    s.s_state AS store_state,
    cc.cc_division_name AS call_center_division,
    wsite.web_market_manager AS web_market_manager,
    CASE
        WHEN d_sold.d_date BETWEEN d_cc_open.d_date AND d_cc_closed.d_date THEN 'Open'
        ELSE 'Closed'
    END AS call_center_status_at_sale,
    date_diff('day', d_web_open.d_date, d_web_close.d_date) AS site_operational_days,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_web_open
    ON wsite.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close
    ON wsite.web_close_date_sk = d_web_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
  AND wsite.web_state IS NOT NULL
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_sold.d_month_seq,
    s.s_state,
    cc.cc_division_name,
    wsite.web_market_manager,
    CASE
        WHEN d_sold.d_date BETWEEN d_cc_open.d_date AND d_cc_closed.d_date THEN 'Open'
        ELSE 'Closed'
    END,
    date_diff('day', d_web_open.d_date, d_web_close.d_date)
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
