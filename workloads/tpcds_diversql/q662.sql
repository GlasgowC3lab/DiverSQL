WITH
    page_agg AS (
        SELECT
            cp_catalog_page_sk,
            COUNT(*) AS page_cnt,
            SUM(cp_catalog_number) AS sum_catalog_num
        FROM catalog_page
        WHERE cp_department = 'Electronics'
          AND cp_start_date_sk > 2450900
        GROUP BY cp_catalog_page_sk
    ),
    intersect_reasons AS (
        SELECT r_reason_sk FROM reason WHERE r_reason_id LIKE 'AAAA%'
        INTERSECT
        SELECT cr_reason_sk FROM catalog_returns WHERE cr_return_amount > 1000
    ),
    union_aggregates AS (
        SELECT
            r.r_reason_sk,
            r.r_reason_desc,
            SUM(cr.cr_return_amount) AS total_return_amount,
            SUM(cr.cr_return_quantity) AS total_return_qty,
            COUNT(*) AS cnt_returns
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN page_agg pa ON cr.cr_catalog_page_sk = pa.cp_catalog_page_sk
        WHERE d.d_year = 2000
          AND cr.cr_return_quantity > 1
          AND cr.cr_return_amount > 1000
          AND r.r_reason_sk IN (SELECT r_reason_sk FROM intersect_reasons)
        GROUP BY r.r_reason_sk, r.r_reason_desc
    ),
    union_aggregates_alt AS (
        SELECT
            r.r_reason_sk,
            r.r_reason_desc,
            SUM(cr.cr_return_amount) AS total_return_amount,
            SUM(cr.cr_return_quantity) AS total_return_qty,
            COUNT(*) AS cnt_returns
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN page_agg pa ON cr.cr_catalog_page_sk = pa.cp_catalog_page_sk
        WHERE d.d_year = 2001
          AND cr.cr_return_quantity > 2
          AND cr.cr_return_amount > 1500
          AND r.r_reason_sk IN (SELECT r_reason_sk FROM intersect_reasons)
        GROUP BY r.r_reason_sk, r.r_reason_desc
    ),
    combined AS (
        SELECT r_reason_sk, r_reason_desc, total_return_amount, total_return_qty, cnt_returns
        FROM union_aggregates
        UNION
        SELECT r_reason_sk, r_reason_desc, total_return_amount, total_return_qty, cnt_returns
        FROM union_aggregates_alt
    ),
    aggregate_cte AS (
        SELECT
            c.r_reason_sk,
            c.r_reason_desc,
            SUM(c.total_return_amount) AS sum_total_return_amount,
            SUM(c.total_return_qty) AS sum_total_return_qty,
            COUNT(*) AS count_rows
        FROM combined c
        GROUP BY c.r_reason_sk, c.r_reason_desc
        HAVING SUM(c.total_return_amount) > 10000
    )
SELECT
    a.r_reason_sk,
    a.r_reason_desc,
    a.sum_total_return_amount,
    a.sum_total_return_qty,
    a.count_rows,
    LAG(a.sum_total_return_amount) OVER (PARTITION BY a.r_reason_desc ORDER BY a.sum_total_return_amount DESC) AS lag_sum_total_return_amount,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_reason_sk = a.r_reason_sk) AS avg_return_amount_per_reason
FROM aggregate_cte a
WHERE a.sum_total_return_amount > 5000
ORDER BY a.sum_total_return_amount DESC
OFFSET 20 ROWS
LIMIT 100
