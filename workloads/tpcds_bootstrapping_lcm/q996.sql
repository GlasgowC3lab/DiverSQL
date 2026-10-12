WITH store_dates AS (
    SELECT
        s.s_store_id,
        s.s_closed_date_sk,
        d.d_date AS store_closed_date,
        d.d_year AS store_closed_year,
        d.d_month_seq AS store_closed_month_seq
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
)
SELECT
    sd.s_store_id,
    wsite.web_site_id,
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    SUM(ws.ws_net_paid) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT wr.wr_order_number) AS total_returns,
    CASE
        WHEN COUNT(DISTINCT ws.ws_order_number) = 0 THEN 0
        ELSE COUNT(DISTINCT wr.wr_order_number) * 1.0 / COUNT(DISTINCT ws.ws_order_number)
    END AS return_rate,
    d_site_open.d_date AS site_open_date,
    d_site_close.d_date AS site_close_date,
    sd.store_closed_date
FROM web_sales ws
JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_site_open ON wsite.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close ON wsite.web_close_date_sk = d_site_close.d_date_sk
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
    AND ws.ws_order_number = wr.wr_order_number
LEFT JOIN date_dim d_returns ON wr.wr_returned_date_sk = d_returns.d_date_sk
CROSS JOIN store_dates sd
WHERE d_sales.d_year = 2022
GROUP BY
    sd.s_store_id,
    wsite.web_site_id,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    d_site_open.d_date,
    d_site_close.d_date,
    sd.store_closed_date
