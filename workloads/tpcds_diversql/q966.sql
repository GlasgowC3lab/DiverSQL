WITH
    inv_agg AS (
        SELECT
            inv_date_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory TABLESAMPLE BERNOULLI (10)
        WHERE inv_quantity_on_hand > 300
          AND inv_warehouse_sk IN (1, 5)
        GROUP BY inv_date_sk, inv_warehouse_sk
    ),
    inv_join AS (
        SELECT
            i.inv_date_sk,
            i.inv_warehouse_sk,
            i.total_qty,
            d.d_year,
            d.d_date_sk AS date_key
        FROM inv_agg i
        JOIN date_dim d
          ON i.inv_date_sk = d.d_date_sk
        WHERE d.d_moy = 12
    ),
    sales_sample AS (
        SELECT
            ws_sold_date_sk,
            ws_ship_date_sk,
            ws_ship_mode_sk,
            ws_bill_addr_sk,
            ws_net_paid,
            ws_net_paid_inc_tax,
            ws_order_number
        FROM web_sales TABLESAMPLE BERNOULLI (5)
        WHERE ws_net_paid BETWEEN 500 AND 5000
          AND ws_net_paid_inc_tax < 4000
    ),
    sales_join AS (
        SELECT
            s.ws_order_number,
            s.ws_sold_date_sk,
            s.ws_ship_mode_sk,
            s.ws_bill_addr_sk,
            s.ws_net_paid,
            s.ws_net_paid_inc_tax,
            d_sold.d_year AS sold_year,
            d_sold.d_date_sk AS date_key,
            sm.sm_type,
            ca.ca_state
        FROM sales_sample s
        JOIN date_dim d_sold
          ON s.ws_sold_date_sk = d_sold.d_date_sk
        JOIN ship_mode sm
          ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_address ca
          ON s.ws_bill_addr_sk = ca.ca_address_sk
        WHERE d_sold.d_moy = 6
          AND ca.ca_state = 'CA'
          AND sm.sm_type = 'AIR'
    ),
    except_orders AS (
        SELECT ws_order_number
        FROM sales_join
        WHERE ws_net_paid > 3000
        EXCEPT
        SELECT ws_order_number
        FROM sales_join
        WHERE ws_net_paid < 1000
    ),
    full_joined AS (
        SELECT
            COALESCE(s.ws_order_number, i.inv_warehouse_sk) AS key_id,
            s.sm_type,
            s.sold_year,
            i.total_qty,
            s.ws_net_paid,
            s.ws_net_paid_inc_tax,
            s.ws_order_number
        FROM sales_join s
        FULL OUTER JOIN inv_join i
          ON s.date_key = i.date_key
    ),
    union_all AS (
        SELECT
            key_id,
            sm_type,
            sold_year,
            total_qty,
            ws_net_paid,
            ws_net_paid_inc_tax,
            ws_order_number
        FROM full_joined
        UNION
        SELECT
            NULL AS key_id,
            sm_type,
            sold_year,
            NULL AS total_qty,
            ws_net_paid,
            NULL AS ws_net_paid_inc_tax,
            ws_order_number
        FROM sales_join
        WHERE ws_net_paid > 2500
    )
SELECT
    sm_type,
    sold_year,
    SUM(total_qty) AS sum_qty,
    AVG(ws_net_paid) AS avg_net_paid,
    COUNT(DISTINCT ws_order_number) AS cnt_orders,
    MIN(ws_net_paid_inc_tax) AS min_net_paid_inc_tax,
    MAX(ws_net_paid_inc_tax) AS max_net_paid_inc_tax,
    (SELECT MAX(d_year) FROM date_dim) AS max_year_overall
FROM union_all
WHERE ws_order_number IS NOT NULL
  AND ws_order_number IN (SELECT ws_order_number FROM except_orders)
GROUP BY ROLLUP (sm_type, sold_year)
ORDER BY sm_type NULLS LAST, sold_year NULLS LAST
LIMIT 100
