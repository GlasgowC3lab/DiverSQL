WITH catalog_part AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY r.r_reason_desc,
        CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END
),
store_part AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        CASE WHEN sr.sr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY r.r_reason_desc,
        CASE WHEN sr.sr_net_loss > 100 THEN 'High' ELSE 'Low' END
),
combined AS (
    SELECT reason_desc, loss_category, total_net_loss FROM catalog_part
    UNION ALL
    SELECT reason_desc, loss_category, total_net_loss FROM store_part
)
SELECT
    reason_desc,
    loss_category,
    SUM(total_net_loss) AS total_loss
FROM combined
GROUP BY reason_desc, loss_category
ORDER BY total_loss DESC
LIMIT 100
