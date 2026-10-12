WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        wsit.web_name,
        wsit.web_city,
        cp.cp_department,
        cp.cp_catalog_page_number,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN date_dim d_ws_open
        ON wsit.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON wsit.web_close_date_sk = d_ws_close.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
        AND cp.cp_end_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_date_sk BETWEEN d_ws_open.d_date_sk AND d_ws_close.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        wsit.web_name,
        wsit.web_city,
        cp.cp_department,
        cp.cp_catalog_page_number,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    web_name,
    web_city,
    cp_department,
    cp_catalog_page_number,
    sold_year,
    sold_month,
    total_net_profit,
    total_quantity,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
