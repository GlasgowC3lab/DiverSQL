SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_department,
    sm.sm_type AS ship_mode_type,
    stats.avg_return_amount,
    stats.avg_sales_net_paid,
    stats.avg_sales_net_paid - stats.avg_return_amount AS diff,
    CASE
        WHEN stats.avg_sales_net_paid - stats.avg_return_amount > 0 THEN 'Advantageous'
        ELSE 'Disadvantageous'
    END AS diff_category,
    RANK() OVER (ORDER BY stats.avg_sales_net_paid - stats.avg_return_amount DESC) AS diff_rank
FROM catalog_page cp
JOIN catalog_returns cr
    ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN LATERAL (
    SELECT
        AVG(ws.ws_net_paid_inc_ship_tax) AS avg_sales_net_paid,
        AVG(cr2.cr_return_amount) AS avg_return_amount
    FROM web_sales ws
    JOIN ship_mode sm2
        ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN catalog_returns cr2
        ON cr2.cr_ship_mode_sk = sm2.sm_ship_mode_sk
    WHERE sm2.sm_ship_mode_sk = sm.sm_ship_mode_sk
      AND cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
) stats
ORDER BY diff_rank
LIMIT 20
