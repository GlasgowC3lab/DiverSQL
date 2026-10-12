/*
  Goal: Analyze web return performance by call‑center state, catalog department and year, 
  comparing return amounts to the overall average while showcasing advanced Trino features:
  - TABLESAMPLE BERNOULLI
  - scalar sub‑query comparison
  - multiple aliases of the same tables (date_dim, reason, call_center)
  - FULL OUTER JOIN
  - EXCEPT set subtraction
  - pagination with ORDER BY / OFFSET / FETCH
*/
WITH wr_sample AS (
    SELECT
        wr_returned_date_sk,
        wr_reason_sk,
        wr_return_amt_inc_tax,
        wr_return_ship_cost,
        wr_order_number
    FROM web_returns
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        cc.cc_state,
        cp.cp_department,
        d_ret.d_year,
        r1.r_reason_desc,
        SUM(wr.wr_return_amt_inc_tax) AS total_return,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_ship_cost) AS avg_ship_cost
    FROM wr_sample wr
    /* join to the return date */
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    /* reason for the return (first alias) */
    JOIN reason r1
        ON wr.wr_reason_sk = r1.r_reason_sk
    /* call centre that was open on the return date */
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_ret.d_date_sk
    /* closed‑date dimension for the same call centre */
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    /* catalog page that started on the closed‑date */
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_cc_closed.d_date_sk
    /* explicit start‑date dimension for the catalog page */
    JOIN date_dim d_cat_start
        ON cp.cp_start_date_sk = d_cat_start.d_date_sk
    /* explicit end‑date dimension for the catalog page */
    JOIN date_dim d_cat_end
        ON cp.cp_end_date_sk = d_cat_end.d_date_sk
    /* reason for the return (second alias, used for a second join) */
    JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
    /* full outer join with a filtered extra call‑centre set */
    FULL OUTER JOIN (
        SELECT cc2.cc_state, cc2.cc_tax_percentage
        FROM call_center cc2
        WHERE cc2.cc_tax_percentage > 0.05
    ) cc_extra
        ON cc.cc_state = cc_extra.cc_state
    /* keep only returns that are above the overall average amount */
    WHERE wr.wr_return_amt_inc_tax > (
        SELECT AVG(wr_return_amt_inc_tax) FROM web_returns
    )
    GROUP BY cc.cc_state, cp.cp_department, d_ret.d_year, r1.r_reason_desc
)
SELECT
    cc_state,
    cp_department,
    d_year,
    r_reason_desc,
    total_return,
    return_cnt,
    avg_ship_cost
FROM (
    SELECT * FROM joined_data
    EXCEPT
    SELECT * FROM joined_data WHERE avg_ship_cost < 20
) result_set
ORDER BY total_return DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
