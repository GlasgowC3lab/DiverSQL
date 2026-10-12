WITH return_summary AS (
    SELECT
        cp.cp_department,
        i.i_brand,
        r.r_reason_desc,
        sm.sm_code,
        w.w_state,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_qty,
        COUNT(*) AS return_cnt
    FROM catalog_page cp
    FULL OUTER JOIN catalog_returns cr
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND r.r_reason_desc LIKE '%price%'
      AND sm.sm_code = 'AIR'
      AND w.w_state = 'CA'
      AND cr.cr_return_quantity > 0
    GROUP BY
        cp.cp_department,
        i.i_brand,
        r.r_reason_desc,
        sm.sm_code,
        w.w_state,
        d.d_year
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn,
    cp_department,
    i_brand,
    r_reason_desc,
    sm_code,
    w_state,
    d_year,
    total_return_amount,
    total_qty,
    return_cnt,
    total_return_amount / return_cnt AS avg_return_amount
FROM return_summary
ORDER BY total_return_amount DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
