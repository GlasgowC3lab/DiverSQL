WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_quantity,
        ws.ws_sold_time_sk,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        wp.wp_url,
        t.t_hour,
        t.t_minute
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 1000
      AND cd.cd_dep_employed_count >= 2
      AND ca.ca_state IN ('CA', 'TX', 'NY')
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_time_sk,
        c.c_customer_id AS ret_customer_id,
        cd.cd_gender AS ret_gender,
        ca.ca_state AS ret_state,
        t.t_hour AS ret_hour,
        t.t_minute AS ret_minute
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_return_amount > 100
      AND cd.cd_dep_employed_count >= 2
      AND ca.ca_state IN ('CA', 'TX', 'NY')
),
sales_orders AS (
    SELECT DISTINCT ws_order_number AS order_number FROM sales
),
return_orders AS (
    SELECT DISTINCT cr_order_number AS order_number FROM returns
),
orders_without_returns AS (
    SELECT order_number FROM sales_orders
    EXCEPT
    SELECT order_number FROM return_orders
),
orders_with_both AS (
    SELECT order_number FROM sales_orders
    INTERSECT
    SELECT order_number FROM return_orders
),
combined AS (
    SELECT
        COALESCE(s.ws_order_number, r.cr_order_number) AS order_number,
        s.ws_net_paid_inc_ship_tax,
        r.cr_return_amount,
        s.c_customer_id,
        r.ret_customer_id,
        CASE
            WHEN s.ws_net_paid_inc_ship_tax > 5000 THEN 'HIGH'
            WHEN s.ws_net_paid_inc_ship_tax BETWEEN 2000 AND 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_category,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(s.ws_order_number, r.cr_order_number)
            ORDER BY s.ws_net_paid_inc_ship_tax DESC NULLS LAST
        ) AS rn
    FROM sales s
    FULL OUTER JOIN returns r
        ON s.ws_order_number = r.cr_order_number
        AND s.ws_sold_time_sk = r.cr_returned_time_sk
),
flagged AS (
    SELECT
        c.*,
        CASE WHEN owr.order_number IS NOT NULL THEN TRUE ELSE FALSE END AS only_sales_flag,
        CASE WHEN owb.order_number IS NOT NULL THEN TRUE ELSE FALSE END AS both_flag
    FROM combined c
    LEFT JOIN orders_without_returns owr ON c.order_number = owr.order_number
    LEFT JOIN orders_with_both owb ON c.order_number = owb.order_number
)
SELECT
    order_number,
    ws_net_paid_inc_ship_tax,
    cr_return_amount,
    c_customer_id,
    ret_customer_id,
    sales_category,
    rn,
    only_sales_flag,
    both_flag
FROM flagged
WHERE rn <= 3
ORDER BY sales_category DESC, ws_net_paid_inc_ship_tax DESC
LIMIT 100
