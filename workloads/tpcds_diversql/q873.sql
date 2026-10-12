WITH sampled_cr AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
cr_join AS (
    SELECT DISTINCT
        cc.cc_call_center_id,
        w.w_warehouse_name,
        r.r_reason_desc,
        cr.cr_return_amount
    FROM sampled_cr cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)price')
      AND cc.cc_city LIKE 'C%'
),
cr_join2 AS (
    SELECT DISTINCT
        cc.cc_call_center_id,
        w.w_warehouse_name,
        r.r_reason_desc,
        cr.cr_return_amount
    FROM sampled_cr cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Warranty%'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_return_amt > 100
      )
),
intersected AS (
    SELECT cc_call_center_id, w_warehouse_name
    FROM cr_join
    INTERSECT
    SELECT cc_call_center_id, w_warehouse_name
    FROM cr_join2
),
final AS (
    SELECT
        i.cc_call_center_id,
        i.w_warehouse_name,
        COUNT(*) AS cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM sampled_cr cr2
            WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
        ) AS warehouse_avg_return
    FROM intersected i
    JOIN call_center cc ON cc.cc_call_center_id = i.cc_call_center_id
    JOIN warehouse w ON w.w_warehouse_name = i.w_warehouse_name
    JOIN sampled_cr cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
                     AND cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
          AND inv.inv_quantity_on_hand > 0
    )
    GROUP BY i.cc_call_center_id, i.w_warehouse_name, w.w_warehouse_sk, cc.cc_name, cc.cc_city, cc.cc_state
)
SELECT DISTINCT
    f.cc_call_center_id,
    f.w_warehouse_name,
    f.cnt,
    f.total_return_amount,
    f.avg_return_amount,
    f.warehouse_avg_return,
    substring(cc.cc_name, 1, 5) AS cc_name_prefix,
    cc.cc_city || ', ' || cc.cc_state AS location
FROM final f
JOIN call_center cc ON cc.cc_call_center_id = f.cc_call_center_id
ORDER BY f.total_return_amount DESC
LIMIT 100
