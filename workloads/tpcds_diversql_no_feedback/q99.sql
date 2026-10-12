WITH store_ret AS (
    SELECT
        d.d_year AS year,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, r.r_reason_desc
    HAVING SUM(sr.sr_net_loss) > 1000
),
catalog_ret AS (
    SELECT
        d.d_year AS year,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, r.r_reason_desc
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT 'store'   AS source, year, reason_desc, total_loss FROM store_ret
UNION ALL
SELECT 'catalog' AS source, year, reason_desc, total_loss FROM catalog_ret
ORDER BY year, total_loss DESC
LIMIT 100
