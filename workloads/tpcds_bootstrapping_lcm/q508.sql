SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_store.d_year AS store_close_year,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    ws_site.web_country,
    ws_site.web_name,
    MAX(date_diff('day', d_site_open.d_date, d_site_close.d_date)) AS site_lifespan_days,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
    SUM(CASE WHEN d_ship.d_date <= d_site_close.d_date THEN ws.ws_ext_sales_price ELSE 0 END) AS sales_before_site_close,
    SUM(CASE WHEN d_ship.d_date > d_site_close.d_date THEN ws.ws_ext_sales_price ELSE 0 END) AS sales_after_site_close,
    ROUND(AVG(ws.ws_sales_price) * 100.0 / NULLIF(AVG(ws.ws_list_price), 0), 2) AS avg_price_discount_pct
FROM
    web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_site_open ON ws_site.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close ON ws_site.web_close_date_sk = d_site_close.d_date_sk
    CROSS JOIN store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2020 AND 2022
    AND ws.ws_quantity > 0
GROUP BY
    ROLLUP (
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_store.d_year,
        d_sold.d_year,
        d_sold.d_month_seq,
        ws_site.web_country,
        ws_site.web_name
    )
HAVING
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY
    total_sales DESC
LIMIT 100
