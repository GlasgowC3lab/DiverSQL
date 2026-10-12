/*
Goal: Compare total return amounts by year and return reason for catalog and web channels, then generate a cartesian product with a small set of ship modes (AIR and RAIL) to illustrate how each return aggregate would appear across those ship modes.
*/
WITH catalog_agg AS (
    SELECT 
        d.d_year AS year,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, r.r_reason_desc
),
web_agg AS (
    SELECT 
        d.d_year AS year,
        r.r_reason_desc AS reason,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, r.r_reason_desc
),
combined AS (
    SELECT 'catalog' AS source, year, reason, total_return_amount, return_cnt
    FROM catalog_agg
    UNION ALL
    SELECT 'web' AS source, year, reason, total_return_amount, return_cnt
    FROM web_agg
),
small_ship AS (
    SELECT sm_ship_mode_sk, sm_type
    FROM ship_mode
    WHERE sm_type IN ('AIR', 'RAIL')
)
SELECT 
    c.source,
    c.year,
    c.reason,
    c.total_return_amount,
    c.return_cnt,
    s.sm_type
FROM combined c
CROSS JOIN small_ship s
ORDER BY c.source, c.year DESC, c.total_return_amount DESC
