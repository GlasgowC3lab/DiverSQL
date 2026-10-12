WITH sales_agg AS (
    SELECT
        dd_sold.d_year,
        dd_sold.d_month_seq,
        sm.sm_type,
        st.s_state,
        st.s_city,
        ws_site.web_name,
        ws_site.web_state,
        COUNT(DISTINCT ws.ws_order_number)               AS order_cnt,
        SUM(ws.ws_ext_sales_price)                       AS total_sales,
        SUM(ws.ws_net_profit)                            AS total_profit,
        SUM(ws.ws_ext_discount_amt)                      AS total_discount,
        AVG(ws.ws_quantity)                              AS avg_quantity,
        MIN(dd_sold.d_date)                              AS first_sale_date,
        MAX(dd_sold.d_date)                              AS last_sale_date,
        MIN(dd_ship.d_date)                              AS first_ship_date,
        MAX(dd_ship.d_date)                              AS last_ship_date,
        MIN(dd_web_open.d_date)                          AS site_open_date,
        MAX(dd_web_close.d_date)                         AS site_close_date
    FROM web_sales ws
    JOIN date_dim dd_sold
        ON ws.ws_sold_date_sk = dd_sold.d_date_sk
    JOIN date_dim dd_ship
        ON ws.ws_ship_date_sk = dd_ship.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim dd_web_open
        ON ws_site.web_open_date_sk = dd_web_open.d_date_sk
    JOIN date_dim dd_web_close
        ON ws_site.web_close_date_sk = dd_web_close.d_date_sk
    JOIN store st
        ON st.s_closed_date_sk = dd_sold.d_date_sk
    GROUP BY
        dd_sold.d_year,
        dd_sold.d_month_seq,
        sm.sm_type,
        st.s_state,
        st.s_city,
        ws_site.web_name,
        ws_site.web_state
)
SELECT
    d_year,
    d_month_seq,
    sm_type,
    s_state,
    s_city,
    web_name,
    web_state,
    order_cnt,
    total_sales,
    total_profit,
    total_discount,
    avg_quantity,
    first_sale_date,
    last_sale_date,
    first_ship_date,
    last_ship_date,
    site_open_date,
    site_close_date,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year DESC, profit_rank ASC
LIMIT 200
