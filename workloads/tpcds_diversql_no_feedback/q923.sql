/*
Goal: Identify order numbers and their return amounts that satisfy two different business conditions (reason contains 'color' and returns in year 2000), then remove low‑volume orders. The query joins all seven selected TPC‑DS tables, re‑uses the household_demographics and date_dim tables under different aliases to reach nine join clauses, aggregates returns per order, adds a LAG and a running‑SUM window, and finally applies INTERSECT and EXCEPT set operators.
*/
WITH base_joins AS (
    SELECT
        cr.cr_order_number,
        w.w_warehouse_name,
        r.r_reason_desc,
        d1.d_date,
        cr.cr_return_amount
    FROM catalog_returns cr
    JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk                               -- join 1
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk      -- join 2 (refunded demo)
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk      -- join 3 (returning demo)
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk                               -- join 4
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk                                        -- join 5
    CROSS JOIN web_site ws                                                                   -- join 6 (cross join)
    JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk                    -- join 7
    JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk                 -- join 8
    CROSS JOIN web_page wp                                                                   -- join 9 (cross join)
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk        -- join 10
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk               -- join 11
    WHERE d1.d_year BETWEEN 1999 AND 2002                                                    -- sample filter to keep data manageable
),
agg AS (
    SELECT
        cr_order_number,
        w_warehouse_name,
        r_reason_desc,
        d_date,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM base_joins
    GROUP BY cr_order_number, w_warehouse_name, r_reason_desc, d_date
),
agg_win AS (
    SELECT
        cr_order_number,
        w_warehouse_name,
        r_reason_desc,
        d_date,
        total_return_amount,
        return_cnt,
        LAG(total_return_amount) OVER (PARTITION BY w_warehouse_name ORDER BY d_date) AS prev_total_return,
        SUM(total_return_amount) OVER (
            PARTITION BY w_warehouse_name
            ORDER BY d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_return
    FROM agg
),
sub1 AS (
    SELECT cr_order_number, w_warehouse_name, total_return_amount
    FROM agg_win
    WHERE r_reason_desc LIKE '%color%'
),
sub2 AS (
    SELECT cr_order_number, w_warehouse_name, total_return_amount
    FROM agg_win
    WHERE year(d_date) = 2000
),
sub3 AS (
    SELECT cr_order_number, w_warehouse_name, total_return_amount
    FROM agg_win
    WHERE return_cnt < 5
)
SELECT *
FROM (SELECT cr_order_number, w_warehouse_name, total_return_amount FROM sub1)
INTERSECT
SELECT cr_order_number, w_warehouse_name, total_return_amount FROM sub2
EXCEPT
SELECT cr_order_number, w_warehouse_name, total_return_amount FROM sub3
ORDER BY total_return_amount DESC
LIMIT 100
