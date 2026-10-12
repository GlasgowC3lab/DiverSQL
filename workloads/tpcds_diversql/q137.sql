WITH store_ret AS (
        SELECT
            'store' AS return_type,
            d.d_year AS year,
            r.r_reason_desc AS reason_desc,
            sr.sr_net_loss AS net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE d.d_year BETWEEN 2001 AND 2002
    ),
    catalog_ret AS (
        SELECT
            'catalog' AS return_type,
            d.d_year AS year,
            r.r_reason_desc AS reason_desc,
            cr.cr_net_loss AS net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_year BETWEEN 2001 AND 2002
    )
SELECT
    return_type,
    year,
    reason_desc,
    SUM(net_loss) AS total_net_loss
FROM (
    SELECT return_type, year, reason_desc, net_loss FROM store_ret
    UNION ALL
    SELECT return_type, year, reason_desc, net_loss FROM catalog_ret
) AS combined
GROUP BY ROLLUP (return_type, year, reason_desc)
ORDER BY
    return_type,
    year,
    reason_desc
