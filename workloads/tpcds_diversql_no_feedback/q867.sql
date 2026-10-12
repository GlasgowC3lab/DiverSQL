/*
  Goal: Analyze net profit and return performance per call center for the year 2002, ranking call centers by profit, showing running totals of return amounts, and keeping only those orders that never had a matching web return (anti‑join).
*/
WITH store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit)            AS total_net_profit,
        SUM(ss.ss_ext_sales_price)        AS total_sales
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk
)
SELECT
    cc.cc_name,
    d_sales.d_date,
    d_sales.d_year,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    sm.sm_type,
    r.r_reason_desc,
    ws.ws_net_paid,
    ws.ws_ext_tax,
    total_net_profit,
    SUM(cr.cr_return_amount) OVER (
        PARTITION BY cc.cc_call_center_sk
        ORDER BY d_sales.d_date
        ROWS UNBOUNDED PRECEDING
    )                                      AS running_return_amount,
    LAG(total_net_profit) OVER (
        PARTITION BY cc.cc_call_center_sk
        ORDER BY d_sales.d_date
    )                                      AS lag_total_net_profit,
    ROW_NUMBER() OVER (
        PARTITION BY cc.cc_call_center_sk
        ORDER BY d_sales.d_date DESC
    )                                      AS rn,
    RANK() OVER (
        PARTITION BY cc.cc_call_center_sk
        ORDER BY total_net_profit DESC
    )                                      AS profit_rank
FROM store_sales_agg ssa
JOIN date_dim d_sales
    ON ssa.ss_sold_date_sk = d_sales.d_date_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d_sales.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk      = ws.ws_item_sk
WHERE
    d_sales.d_year = 2002
    AND cc.cc_division_name = 'Division1'
    AND r.r_reason_desc = 'Damaged'
    AND sm.sm_type = 'AIR'
    AND cr.cr_return_amount > 0
    AND wr.wr_order_number IS NULL
ORDER BY
    cc.cc_name,
    d_sales.d_date DESC
LIMIT 100
