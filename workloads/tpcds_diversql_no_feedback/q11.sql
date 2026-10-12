/*
Goal: Compare aggregated monetary impact of catalog return reasons with sales by promotion, retaining all promotions even if they have no sales, and present the combined result ordered by amount.
*/
WITH catalog_ret AS (
    SELECT
        'Return' AS category,
        r.r_reason_id AS id,
        r.r_reason_desc AS description,
        SUM(cr.cr_return_amount) AS amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2450996
    GROUP BY r.r_reason_id, r.r_reason_desc
),
promo_sales AS (
    SELECT
        'Sale' AS category,
        p.p_promo_id AS id,
        p.p_promo_name AS description,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS amount
    FROM web_sales ws
    RIGHT OUTER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk <= 2450996
      AND p.p_end_date_sk >= 2450815
    GROUP BY p.p_promo_id, p.p_promo_name
)
SELECT
    category,
    id,
    description,
    amount
FROM catalog_ret
UNION ALL
SELECT
    category,
    id,
    description,
    amount
FROM promo_sales
ORDER BY amount DESC
LIMIT 100
