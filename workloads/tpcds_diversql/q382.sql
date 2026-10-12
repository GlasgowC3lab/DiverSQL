WITH
    diff_orders AS (
        SELECT cs_order_number FROM catalog_sales
        EXCEPT
        SELECT cr_order_number FROM catalog_returns
    ),
    base_sales AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cs.cs_call_center_sk,
            cs.cs_warehouse_sk,
            cs.cs_item_sk
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 5
          AND cs.cs_net_paid >= 100
    ),
    sales_with_dims AS (
        SELECT
            bs.cs_order_number,
            bs.cs_quantity,
            bs.cs_net_paid,
            bs.cs_net_profit,
            cc.cc_state,
            w.w_city,
            i.inv_quantity_on_hand,
            td.t_second,
            cr.cr_return_amount,
            cr.cr_return_quantity
        FROM base_sales bs
        JOIN call_center cc
          ON bs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w
          ON bs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN inventory i
          ON w.w_warehouse_sk = i.inv_warehouse_sk
        JOIN catalog_returns cr
          ON bs.cs_order_number = cr.cr_order_number
        JOIN time_dim td
          ON bs.cs_sold_time_sk = td.t_time_sk
        WHERE cc.cc_state = 'CA'
          AND w.w_city = 'Liberty'
          AND td.t_second BETWEEN 5 AND 15
          AND i.inv_quantity_on_hand < 500
          AND cr.cr_return_amount > 20
    ),
    sales_right_time AS (
        SELECT
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_net_profit,
            td.t_second,
            cc.cc_state,
            w.w_city
        FROM catalog_sales cs
        RIGHT OUTER JOIN time_dim td
          ON cs.cs_sold_time_sk = td.t_time_sk
        LEFT JOIN call_center cc
          ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN warehouse w
          ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE td.t_second IN (7, 9, 10, 15, 19)
    )
SELECT
    result_key,
    SUM(total_quantity) AS sum_quantity,
    AVG(total_net_paid) AS avg_net_paid,
    COUNT(DISTINCT order_number) AS distinct_orders,
    MIN(min_net_profit) AS min_profit,
    MAX(max_net_profit) AS max_profit
FROM (
    SELECT
        'sales_dims' AS result_key,
        cs_order_number AS order_number,
        cs_quantity AS total_quantity,
        cs_net_paid AS total_net_paid,
        cs_net_profit AS min_net_profit,
        cs_net_profit AS max_net_profit
    FROM sales_with_dims
    UNION
    SELECT
        'sales_right' AS result_key,
        cs_order_number AS order_number,
        cs_quantity AS total_quantity,
        cs_net_paid AS total_net_paid,
        cs_net_profit AS min_net_profit,
        cs_net_profit AS max_net_profit
    FROM sales_right_time
) agg
WHERE order_number IN (SELECT cs_order_number FROM diff_orders)
GROUP BY result_key
ORDER BY sum_quantity DESC
LIMIT 100
