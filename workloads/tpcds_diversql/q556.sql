WITH
    -- Pre‑aggregate store_sales per date and time
    ss_agg AS (
        SELECT
            ss_sold_date_sk,
            ss_sold_time_sk,
            SUM(ss_ext_sales_price)               AS total_sales,
            COUNT(DISTINCT ss_ticket_number)       AS distinct_tickets,
            SUM(ss_net_profit)                     AS total_profit
        FROM store_sales
        WHERE ss_quantity > 0
          AND ss_sales_price > 0
        GROUP BY ss_sold_date_sk, ss_sold_time_sk
    ),
    -- Pre‑aggregate catalog_returns per date, time and call center
    cr_agg AS (
        SELECT
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_call_center_sk,
            SUM(cr_return_amount)                  AS total_return_amount,
            COUNT(DISTINCT cr_order_number)        AS distinct_orders,
            SUM(cr_net_loss)                       AS total_net_loss
        FROM catalog_returns
        WHERE cr_return_quantity > 0
          AND cr_return_amt_inc_tax > 0
        GROUP BY cr_returned_date_sk, cr_returned_time_sk, cr_call_center_sk
    ),
    -- Intersect call‑center keys that appear in both tables
    intersect_cc AS (
        SELECT cc_call_center_sk FROM call_center
        INTERSECT
        SELECT cr_call_center_sk FROM catalog_returns
    ),
    -- Union of two different projections (one uses FULL OUTER JOIN, the other INNER JOIN)
    union_data AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            td.t_hour,
            ss.total_sales,
            cr.total_return_amount,
            cr.distinct_orders,
            ss.distinct_tickets
        FROM call_center cc
        FULL OUTER JOIN cr_agg cr
            ON cc.cc_call_center_sk = cr.cr_call_center_sk
        LEFT JOIN time_dim td
            ON td.t_time_sk = cr.cr_returned_time_sk
        LEFT JOIN ss_agg ss
            ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE cc.cc_state = 'CA'
          AND td.t_hour BETWEEN 8 AND 20

        UNION

        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            td.t_hour,
            ss.total_sales,
            cr.total_return_amount,
            cr.distinct_orders,
            ss.distinct_tickets
        FROM call_center cc
        INNER JOIN cr_agg cr
            ON cc.cc_call_center_sk = cr.cr_call_center_sk
        INNER JOIN time_dim td
            ON td.t_time_sk = cr.cr_returned_time_sk
        INNER JOIN ss_agg ss
            ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE cc.cc_state = 'TX'
          AND td.t_hour BETWEEN 6 AND 18
    ),
    -- Apply calculations, window function and scalar subquery
    final_calc AS (
        SELECT
            ud.cc_call_center_sk,
            ud.cc_name,
            ud.t_hour,
            ud.total_sales,
            ud.total_return_amount,
            ud.distinct_orders,
            ud.distinct_tickets,
            CASE
                WHEN ud.total_sales > 0 THEN ROUND(ud.total_return_amount / ud.total_sales, 4)
                ELSE NULL
            END                                               AS return_to_sales_ratio,
            RANK() OVER (PARTITION BY ud.cc_call_center_sk ORDER BY ud.total_sales DESC) AS sales_rank,
            (
                SELECT AVG(cr2.cr_return_amount)
                FROM catalog_returns cr2
                WHERE cr2.cr_call_center_sk = ud.cc_call_center_sk
            )                                                AS avg_return_amount
        FROM union_data ud
        WHERE ud.total_sales IS NOT NULL
    )
SELECT
    fc.cc_call_center_sk,
    fc.cc_name,
    fc.t_hour,
    fc.total_sales,
    fc.total_return_amount,
    fc.return_to_sales_ratio,
    fc.sales_rank,
    fc.avg_return_amount,
    COUNT(DISTINCT fc.t_hour)   OVER () AS distinct_hours,
    COUNT(DISTINCT fc.cc_name) OVER () AS distinct_call_centers
FROM final_calc fc
WHERE fc.sales_rank <= 5
  AND fc.cc_call_center_sk IN (SELECT cc_call_center_sk FROM intersect_cc)
ORDER BY fc.return_to_sales_ratio DESC NULLS LAST, fc.total_sales DESC
LIMIT 100
