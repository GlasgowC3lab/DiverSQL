WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        sm.sm_code,
        sm.sm_carrier,
        r.r_reason_desc,
        d.d_year,
        i.inv_quantity_on_hand,
        wp.wp_type,
        wr.wr_return_amt
    FROM catalog_returns AS cr
    JOIN date_dim AS d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode AS sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason AS r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN (
        SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
    ) AS i
        ON i.inv_date_sk = d.d_date_sk
    JOIN web_page AS wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns AS wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2002
      AND sm.sm_code = 'AIR'
      AND sm.sm_carrier = 'DHL'
      AND i.inv_quantity_on_hand > 100
      AND wp.wp_type = 'HOME'
),
agg1 AS (
    SELECT
        sm_code,
        r_reason_desc,
        d_year,
        SUM(cr_return_amount) AS total_return_amt,
        COUNT(*) AS cnt,
        AVG(cr_return_amount) AS avg_return_amt
    FROM base
    GROUP BY sm_code, r_reason_desc, d_year
)
SELECT
    sm_code,
    r_reason_desc,
    total_return_amt,
    cnt,
    avg_return_amt
FROM agg1
WHERE total_return_amt > (
        SELECT MAX(total_return_amt) FROM agg1
    ) / 2
ORDER BY total_return_amt DESC
LIMIT 100
