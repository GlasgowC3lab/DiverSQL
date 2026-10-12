WITH
    cr_agg AS (
        SELECT
            cr_item_sk,
            cr_catalog_page_sk,
            cr_reason_sk,
            SUM(cr_return_amount) AS total_cr_amount,
            COUNT(*) AS cnt_cr
        FROM catalog_returns
        WHERE cr_return_tax > 30.00
          AND cr_returned_date_sk BETWEEN 2450000 AND 2450100
          AND cr_returned_time_sk = 12345
        GROUP BY cr_item_sk, cr_catalog_page_sk, cr_reason_sk
    ),
    sr_agg AS (
        SELECT
            sr_item_sk,
            sr_reason_sk,
            SUM(sr_return_amt) AS total_sr_amount,
            COUNT(*) AS cnt_sr
        FROM store_returns
        WHERE sr_return_tax > 20.00
          AND sr_returned_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY sr_item_sk, sr_reason_sk
    ),
    item_sample AS (
        SELECT *
        FROM item TABLESAMPLE BERNOULLI (15)
    ),
    missing_items AS (
        SELECT cr_item_sk FROM cr_agg
        EXCEPT
        SELECT sr_item_sk FROM sr_agg
    ),
    reason_subset AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
        WHERE r_reason_id IN ('R1','R2','R3')
    )
SELECT
    cp.cp_catalog_page_id,
    cp.cp_description,
    i.i_product_name,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_sr.r_reason_desc AS store_return_reason,
    cr_agg.total_cr_amount,
    sr_agg.total_sr_amount,
    cr_agg.cnt_cr,
    sr_agg.cnt_sr,
    l.avg_sr_return,
    vt.price_tier
FROM item_sample i
JOIN cr_agg ON i.i_item_sk = cr_agg.cr_item_sk
JOIN sr_agg ON i.i_item_sk = sr_agg.sr_item_sk
JOIN catalog_page cp ON cr_agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r_cr ON cr_agg.cr_reason_sk = r_cr.r_reason_sk
JOIN reason r_sr ON sr_agg.sr_reason_sk = r_sr.r_reason_sk
JOIN missing_items mi ON i.i_item_sk = mi.cr_item_sk
JOIN reason_subset rs ON r_cr.r_reason_sk = rs.r_reason_sk
CROSS JOIN (VALUES (1), (2), (3)) AS vt(price_tier)
LEFT JOIN LATERAL (
    SELECT AVG(sr_return_amt) AS avg_sr_return
    FROM store_returns sr
    WHERE sr.sr_item_sk = i.i_item_sk
) l ON TRUE
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp2
    WHERE cp2.cp_catalog_page_sk = cp.cp_catalog_page_sk
      AND cp2.cp_type = 'Online'
)
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_description,
    i.i_product_name,
    r_cr.r_reason_desc,
    r_sr.r_reason_desc,
    cr_agg.total_cr_amount,
    sr_agg.total_sr_amount,
    cr_agg.cnt_cr,
    sr_agg.cnt_sr,
    l.avg_sr_return,
    vt.price_tier
ORDER BY cr_agg.total_cr_amount DESC
LIMIT 100
