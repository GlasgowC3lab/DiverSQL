WITH agg AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        s.s_store_id,
        s.s_city AS store_city,
        s.s_state AS store_state,
        web.web_site_sk,
        web.web_name,
        web.web_city,
        web.web_state,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS combined_sales,
        SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS combined_profit,
        d_ship.d_month_seq AS ship_month,
        d_ship.d_year AS ship_year,
        d_store_closed.d_year AS store_closed_year,
        d_site_open.d_year AS site_open_year,
        d_site_close.d_year AS site_close_year
    FROM date_dim d_sold
    JOIN store_sales ss ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    LEFT JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    LEFT JOIN date_dim d_site_open ON web.web_open_date_sk = d_site_open.d_date_sk
    LEFT JOIN date_dim d_site_close ON web.web_close_date_sk = d_site_close.d_date_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state,
        web.web_site_sk,
        web.web_name,
        web.web_city,
        web.web_state,
        d_ship.d_month_seq,
        d_ship.d_year,
        d_store_closed.d_year,
        d_site_open.d_year,
        d_site_close.d_year
)
SELECT
    d_year,
    d_month_seq,
    s_store_id,
    store_city,
    store_state,
    web_site_sk,
    web_name,
    web_city,
    web_state,
    total_store_sales,
    total_store_profit,
    total_web_sales,
    total_web_profit,
    combined_sales,
    combined_profit,
    ship_month,
    ship_year,
    store_closed_year,
    site_open_year,
    site_close_year,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY combined_sales DESC) AS sales_rank
FROM agg
ORDER BY combined_sales DESC
LIMIT 100
