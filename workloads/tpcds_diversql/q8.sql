WITH store_agg AS (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(sr.sr_net_loss) AS total_loss,
           'store' AS source
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
),
catalog_agg AS (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(cr.cr_net_loss) AS total_loss,
           'catalog' AS source
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
),
ranked AS (
    SELECT reason_desc,
           total_loss,
           source,
           ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_loss DESC) AS rn
    FROM combined
)
SELECT d.c_preferred_cust_flag,
       r.reason_desc,
       r.total_loss,
       r.source
FROM ranked r
CROSS JOIN (
    SELECT DISTINCT c.c_preferred_cust_flag
    FROM customer c
    WHERE c.c_preferred_cust_flag IS NOT NULL
) d
WHERE r.rn <= 3
ORDER BY r.source, r.total_loss DESC
LIMIT 100
