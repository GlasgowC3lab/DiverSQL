WITH base AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        sm.sm_type,
        cd.cd_education_status,
        cp.cp_catalog_page_sk,
        cp.cp_description,
        cp.cp_catalog_page_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number,
        sr.sr_return_amt,
        sr.sr_return_quantity
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cd.cd_education_status = 'Advanced Degree'
      AND cd.cd_dep_count >= 3
      AND cp.cp_catalog_page_number IN (1, 3, 6)
      AND cr.cr_return_amount > 100.00
),
aggregated AS (
    SELECT
        b.cc_name,
        b.sm_type,
        b.cd_education_status,
        SUM(b.cr_return_amount) AS total_catalog_return_amount,
        SUM(b.sr_return_amt) AS total_store_return_amount,
        COUNT(DISTINCT b.cr_order_number) AS distinct_orders,
        AVG(b.cr_return_quantity) AS avg_catalog_return_qty,
        d.first_word
    FROM base b
    LEFT JOIN LATERAL (
        SELECT split_part(b.cp_description, ' ', 1) AS first_word
    ) d ON true
    GROUP BY b.cc_name, b.sm_type, b.cd_education_status, d.first_word
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_catalog_return_amount DESC) AS rn
    FROM aggregated
)
SELECT
    cc_name,
    sm_type,
    cd_education_status,
    total_catalog_return_amount,
    total_store_return_amount,
    distinct_orders,
    avg_catalog_return_qty,
    first_word
FROM ranked
WHERE rn <= 3
ORDER BY cc_name, total_catalog_return_amount DESC
