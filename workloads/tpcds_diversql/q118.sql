WITH joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_wholesale_cost AS ss_ext_wholesale_cost,
        ss.ss_ext_tax AS ss_ext_tax,
        ss.ss_coupon_amt AS ss_coupon_amt,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_quantity AS ws_quantity,
        ws.ws_ext_tax AS ws_ext_tax,
        ws.ws_coupon_amt AS ws_coupon_amt,
        i.inv_quantity_on_hand,
        w.w_warehouse_name,
        d1.d_year,
        t.t_hour,
        st.s_store_name,
        st.s_state,
        w.w_state,
        wp.wp_type,
        wp.wp_url,
        split(wp.wp_url, '/') AS url_parts
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN inventory i ON ss.ss_sold_date_sk = i.inv_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
                     AND ss.ss_sold_time_sk = ws.ws_sold_time_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d2 ON ws.ws_ship_date_sk = d2.d_date_sk
    JOIN date_dim d3 ON st.s_closed_date_sk = d3.d_date_sk
    JOIN date_dim d4 ON wp.wp_creation_date_sk = d4.d_date_sk
    JOIN date_dim d5 ON wp.wp_access_date_sk = d5.d_date_sk
    WHERE d1.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND st.s_state = 'CA'
      AND w.w_state = 'CA'
      AND wp.wp_type = 'order'
      AND ss.ss_quantity > 1
      AND ws.ws_quantity > 0
      AND ss.ss_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 100)
),
exploded AS (
    SELECT
        j.d_year,
        j.s_store_name,
        j.w_warehouse_name,
        j.wp_type,
        j.ss_ext_sales_price,
        j.ws_ext_sales_price,
        j.ss_net_profit,
        j.ws_net_profit,
        url_part
    FROM joined j
    CROSS JOIN UNNEST(j.url_parts) AS t(url_part)
)
SELECT
    d_year AS year,
    s_store_name AS store_name,
    w_warehouse_name AS warehouse_name,
    wp_type,
    COUNT(DISTINCT url_part) AS distinct_url_segments,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(ss_net_profit + ws_net_profit) AS total_net_profit,
    AVG(ss_ext_sales_price + ws_ext_sales_price) AS avg_combined_sales
FROM exploded
GROUP BY d_year, s_store_name, w_warehouse_name, wp_type
HAVING SUM(ss_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
