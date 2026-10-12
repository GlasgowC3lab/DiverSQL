WITH union_agg AS (
    /* Store returns aggregation */
    SELECT r.r_reason_desc AS reason_desc,
           SUM(sr.sr_net_loss) AS total_loss,
           CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND regexp_like(r.r_reason_desc, '^Found a better')
      AND r.r_reason_desc LIKE '%price%'
    GROUP BY r.r_reason_desc
    HAVING SUM(sr.sr_net_loss) > 500

    UNION

    /* Catalog returns aggregation with promotion filter */
    SELECT r.r_reason_desc,
           SUM(cr.cr_net_loss) AS total_loss,
           CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND regexp_like(r.r_reason_desc, '^Found a better')
      AND r.r_reason_desc LIKE '%price%'
      AND regexp_extract(p.p_promo_name, '(Discount)', 1) = 'Discount'
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_net_loss) > 500
),
intersect_set AS (
    SELECT r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND regexp_like(r.r_reason_desc, '^Found a better')
)
SELECT CONCAT('Reason: ', u.reason_desc) AS reason_text,
       u.total_loss,
       u.loss_flag
FROM union_agg u
WHERE u.total_loss > 1000
  AND u.reason_desc IN (
        SELECT reason_desc FROM (
            SELECT reason_desc FROM union_agg
            INTERSECT
            SELECT reason_desc FROM intersect_set
        ) AS inter
    )
ORDER BY u.total_loss DESC
LIMIT 100
