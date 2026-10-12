WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        d.d_year,
        d.d_date,
        t.t_hour,
        sm.sm_type,
        sm.sm_carrier,
        c.c_birth_month,
        c.c_preferred_cust_flag,
        wp.wp_type,
        wp.wp_url,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year = 1999
      AND sm.sm_type = 'AIR'
      AND c.c_birth_month IN (4, 5)
      AND wp.wp_type = 'content'
      AND d.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
),

agg_cube AS (
    SELECT
        d_year,
        sm_type,
        c_birth_month,
        wp_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(*) AS order_cnt
    FROM base
    GROUP BY CUBE (d_year, sm_type, c_birth_month, wp_type)
),

expanded AS (
    SELECT
        ac.d_year,
        ac.sm_type,
        ac.c_birth_month,
        ac.wp_type,
        metric_name,
        metric_value
    FROM agg_cube ac
    CROSS JOIN UNNEST(
        ARRAY[ac.total_sales, ac.total_quantity],
        ARRAY['sales', 'quantity']
    ) AS t(metric_value, metric_name)
),

qty_range AS (
    SELECT ws_order_number FROM base WHERE ws_quantity > 5
    EXCEPT
    SELECT ws_order_number FROM base WHERE ws_quantity > 10
),

orders_with_sales AS (
    SELECT ws_order_number FROM base WHERE ws_ext_sales_price > 1000
),

orders_with_return AS (
    SELECT ws_order_number FROM base WHERE wr_return_amt > 0
),

orders_both AS (
    SELECT ws_order_number FROM orders_with_sales
    INTERSECT
    SELECT ws_order_number FROM orders_with_return
),

ship_page_full AS (
    SELECT sm.sm_ship_mode_sk,
           sm.sm_type,
           wp.wp_web_page_sk,
           wp.wp_type
    FROM ship_mode sm
    FULL OUTER JOIN web_page wp ON sm.sm_ship_mode_sk = -1
),

final_set AS (
    SELECT DISTINCT
        e.d_year,
        e.sm_type,
        e.c_birth_month,
        e.wp_type,
        e.metric_name,
        e.metric_value,
        CASE WHEN q.ws_order_number IS NOT NULL THEN 1 ELSE 0 END AS qty_range_flag,
        CASE WHEN o.ws_order_number IS NOT NULL THEN 1 ELSE 0 END AS orders_both_flag
    FROM expanded e
    JOIN base b ON e.d_year = b.d_year
                AND e.sm_type = b.sm_type
                AND e.c_birth_month = b.c_birth_month
                AND e.wp_type = b.wp_type
    LEFT JOIN qty_range q ON b.ws_order_number = q.ws_order_number
    LEFT JOIN orders_both o ON b.ws_order_number = o.ws_order_number
)
SELECT
    d_year,
    sm_type,
    c_birth_month,
    wp_type,
    metric_name,
    metric_value,
    qty_range_flag,
    orders_both_flag
FROM final_set
ORDER BY metric_value DESC
LIMIT 100
