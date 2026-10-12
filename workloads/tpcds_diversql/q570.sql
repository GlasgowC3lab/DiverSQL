/*
Goal: Identify, per warehouse and meal time, the total web sales and total returns for orders that have no associated returns, rank warehouses by sales, and show running totals and lag values. The query joins all five TPC‑DS tables, uses a FULL OUTER JOIN, excludes orders that appear in returns via EXCEPT, assigns a ROW_NUMBER, and applies a LAG and a running SUM analytic window. Five filter predicates are applied across the CTEs and final step.
*/
WITH base_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_ship_cost,
        t.t_meal_time,
        w.w_warehouse_name,
        p.wp_type
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page p
        ON ws.ws_web_page_sk = p.wp_web_page_sk
    WHERE t.t_meal_time IN ('breakfast', 'lunch', 'dinner')
      AND ws.ws_ext_ship_cost > 500
      AND ws.ws_quantity >= 1
      AND ws.ws_net_paid_inc_ship BETWEEN 1000 AND 10000
      AND w.w_gmt_offset >= -5
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt)          AS total_return_amt,
        SUM(wr.wr_refunded_cash)       AS total_refunded_cash,
        MAX(wr.wr_returned_time_sk)    AS max_return_time_sk
    FROM web_returns wr
    JOIN time_dim t_ret
        ON wr.wr_returned_time_sk = t_ret.t_time_sk
    WHERE t_ret.t_am_pm = 'PM'
      AND wr.wr_return_amt > 0
      AND wr.wr_refunded_cash > 0
      AND wr.wr_account_credit < 500
      AND wr.wr_fee BETWEEN 0 AND 100
    GROUP BY wr.wr_order_number
),
full_join AS (
    SELECT
        COALESCE(bs.ws_order_number, ra.wr_order_number) AS order_number,
        bs.ws_sold_date_sk,
        bs.ws_quantity,
        bs.ws_ext_sales_price,
        bs.ws_net_paid_inc_ship,
        ra.total_return_amt,
        ra.total_refunded_cash,
        bs.t_meal_time,
        bs.w_warehouse_name,
        bs.wp_type
    FROM base_sales bs
    FULL OUTER JOIN returns_agg ra
        ON bs.ws_order_number = ra.wr_order_number
),
orders_without_returns AS (
    SELECT ws_order_number AS order_number FROM web_sales
    EXCEPT
    SELECT wr_order_number   AS order_number FROM web_returns
),
filtered AS (
    SELECT fj.*
    FROM full_join fj
    INNER JOIN orders_without_returns owr
        ON fj.order_number = owr.order_number
),
final_agg AS (
    SELECT
        f.w_warehouse_name,
        f.t_meal_time,
        SUM(COALESCE(f.ws_ext_sales_price, 0)) AS total_sales,
        SUM(COALESCE(f.total_return_amt, 0))   AS total_returns,
        COUNT(DISTINCT f.order_number)          AS num_orders
    FROM filtered f
    GROUP BY f.w_warehouse_name, f.t_meal_time
)
SELECT
    fa.w_warehouse_name,
    fa.t_meal_time,
    fa.total_sales,
    fa.total_returns,
    fa.num_orders,
    (fa.total_sales - fa.total_returns) / NULLIF(fa.num_orders, 0) AS avg_net_per_order,
    ROW_NUMBER() OVER (PARTITION BY fa.w_warehouse_name ORDER BY fa.total_sales DESC) AS rn_sales_rank,
    LAG(fa.total_sales) OVER (PARTITION BY fa.w_warehouse_name ORDER BY fa.total_sales DESC) AS lag_total_sales,
    SUM(fa.total_sales) OVER (PARTITION BY fa.w_warehouse_name ORDER BY fa.total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM final_agg fa
WHERE fa.total_sales > 1000
  AND fa.total_returns < 5000
  AND fa.num_orders >= 5
  AND fa.w_warehouse_name IS NOT NULL
  AND fa.t_meal_time <> ''
ORDER BY fa.w_warehouse_name, fa.total_sales DESC
LIMIT 100
