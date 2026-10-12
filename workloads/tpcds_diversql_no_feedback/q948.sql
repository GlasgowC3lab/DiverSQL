/*
  Goal: Analyze daily sales and return performance by warehouse, catalog page type and ship carrier for the year 2001, applying several realistic filters. The query joins all eight TPC‑DS tables using only the allowed surrogate‑key relationships, aggregates key monetary measures, computes running totals and previous‑day sales using window functions, and finally de‑duplicates results with a UNION DISTINCT.
*/
WITH joined_data AS (
    SELECT
        w.w_warehouse_name        AS w_warehouse_name,
        w.w_state                AS w_state,
        d.d_date                 AS d_date,
        d.d_year                 AS d_year,
        cp.cp_type               AS cp_type,
        sm.sm_carrier            AS sm_carrier,
        ss.ss_ext_sales_price    AS ss_ext_sales_price,
        cr.cr_return_amount      AS cr_return_amount,
        ss.ss_ticket_number      AS ss_ticket_number,
        ss.ss_net_profit         AS ss_net_profit,
        ss.ss_quantity           AS ss_quantity,
        cr.cr_return_quantity    AS cr_return_quantity,
        ca_ss.ca_state           AS sales_state,
        ca_refund.ca_state       AS refund_state,
        ca_returning.ca_state    AS returning_state
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca_ss
      ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_returning
      ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND cp.cp_type = 'monthly'
      AND w.w_state = 'CA'
      AND ca_ss.ca_state IN ('CA', 'WA')
      AND ss.ss_quantity > 5
      AND cr.cr_return_quantity > 0
),
aggregated AS (
    SELECT
        w_warehouse_name,
        w_state,
        d_date,
        cp_type,
        sm_carrier,
        SUM(ss_ext_sales_price)   AS total_sales,
        SUM(cr_return_amount)     AS total_returns,
        COUNT(DISTINCT ss_ticket_number) AS orders,
        AVG(ss_net_profit)        AS avg_profit,
        MIN(d_date)               AS first_date,
        MAX(d_date)               AS last_date
    FROM joined_data
    GROUP BY w_warehouse_name, w_state, d_date, cp_type, sm_carrier
)
SELECT
    w_warehouse_name,
    w_state,
    d_date,
    cp_type,
    sm_carrier,
    total_sales,
    total_returns,
    orders,
    avg_profit,
    first_date,
    last_date,
    SUM(total_sales) OVER (PARTITION BY w_warehouse_name ORDER BY d_date ROWS UNBOUNDED PRECEDING) AS running_sales,
    LAG(total_sales) OVER (PARTITION BY w_warehouse_name ORDER BY d_date) AS prev_day_sales
FROM aggregated
UNION DISTINCT
SELECT
    w_warehouse_name,
    w_state,
    d_date,
    cp_type,
    sm_carrier,
    total_sales,
    total_returns,
    orders,
    avg_profit,
    first_date,
    last_date,
    SUM(total_sales) OVER (PARTITION BY w_warehouse_name ORDER BY d_date ROWS UNBOUNDED PRECEDING) AS running_sales,
    LAG(total_sales) OVER (PARTITION BY w_warehouse_name ORDER BY d_date) AS prev_day_sales
FROM aggregated
ORDER BY w_warehouse_name, d_date
LIMIT 100
