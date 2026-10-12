WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        sm.sm_type,
        sm.sm_carrier,
        d_closed.d_year,
        d_closed.d_month_seq AS closed_month_seq,
        d_ship.d_month_seq AS ship_month_seq,
        d_ship.d_date AS ship_date,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        MIN(d_creation.d_date) AS earliest_page_creation,
        MAX(d_access.d_date) AS latest_page_access
    FROM store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_closed.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE d_closed.d_year = 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        sm.sm_type,
        sm.sm_carrier,
        d_closed.d_year,
        d_closed.d_month_seq,
        d_ship.d_month_seq,
        d_ship.d_date
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.s_city,
    agg.s_state,
    agg.sm_type,
    agg.sm_carrier,
    agg.d_year,
    agg.closed_month_seq,
    agg.ship_month_seq,
    agg.ship_date,
    agg.order_cnt,
    agg.total_quantity,
    agg.total_sales,
    agg.total_net_profit,
    agg.avg_discount,
    agg.distinct_pages,
    agg.earliest_page_creation,
    agg.latest_page_access,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_net_profit DESC) AS profit_rank_year
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 100
