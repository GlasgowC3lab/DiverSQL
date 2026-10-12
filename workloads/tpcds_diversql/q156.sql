WITH joined_data AS (
    SELECT
        s.s_store_name,
        s.s_state,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active,
        sm.sm_code,
        td.t_hour,
        c.c_customer_sk,
        c.c_customer_id,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        wp.wp_type
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_category = 'Electronics'
      AND s.s_state = 'CA'
      AND sm.sm_code = 'AIR'
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    s_store_name,
    s_state,
    i_category,
    p_promo_name,
    sm_code,
    t_hour,
    c_customer_id,
    COUNT(DISTINCT ss_ticket_number) AS transaction_cnt,
    SUM(ss_ext_sales_price) AS total_store_sales,
    AVG(ss_quantity) AS avg_quantity,
    MIN(ss_ext_sales_price) AS min_store_sale,
    MAX(ss_ext_sales_price) AS max_store_sale,
    COUNT(DISTINCT wp_type) AS distinct_page_types,
    (
        SELECT SUM(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = joined_data.c_customer_sk
    ) AS total_web_net_paid
FROM joined_data
GROUP BY
    s_store_name,
    s_state,
    i_category,
    p_promo_name,
    sm_code,
    t_hour,
    c_customer_id,
    c_customer_sk
ORDER BY total_store_sales DESC
LIMIT 100
