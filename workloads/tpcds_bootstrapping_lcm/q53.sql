WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month,
        d_site_open.d_year AS site_open_year,
        d_cc_closed.d_year AS cc_closed_year,
        wsite.web_market_manager,
        s.s_division_name,
        cc.cc_manager,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_coupon_amt) AS avg_coupon,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(d_sold.d_date) AS first_sale_date,
        MAX(d_sold.d_date) AS last_sale_date,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d_site_open
        ON wsite.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close
        ON wsite.web_close_date_sk = d_site_close.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_site_close.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    WHERE d_sold.d_year >= 2020
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        d_site_open.d_year,
        d_cc_closed.d_year,
        wsite.web_market_manager,
        s.s_division_name,
        cc.cc_manager
)
SELECT
    sale_year,
    sale_month,
    site_open_year,
    cc_closed_year,
    web_market_manager,
    s_division_name,
    cc_manager,
    total_sales,
    total_profit,
    num_orders,
    avg_coupon,
    max_sales_price,
    avg_shipping_delay,
    first_sale_date,
    last_sale_date,
    ROW_NUMBER() OVER (PARTITION BY sale_year, sale_month ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY sale_year, sale_month, sales_rank
LIMIT 200
