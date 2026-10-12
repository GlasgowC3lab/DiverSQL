WITH union_sales AS (
    SELECT
        d.d_fy_year,
        d.d_year,
        d.d_month_seq,
        d.d_date_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_moy = 12
    GROUP BY d.d_fy_year, d.d_year, d.d_month_seq, d.d_date_sk

    UNION ALL

    SELECT
        d.d_fy_year,
        d.d_year,
        d.d_month_seq,
        d.d_date_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_moy = 7
    GROUP BY d.d_fy_year, d.d_year, d.d_month_seq, d.d_date_sk
),
ranked_sales AS (
    SELECT
        u.*,
        ROW_NUMBER() OVER (PARTITION BY u.d_fy_year ORDER BY u.total_net_paid DESC) AS rn
    FROM union_sales u
)
SELECT
    r.d_fy_year,
    r.d_year,
    r.d_month_seq,
    r.total_net_paid,
    r.profit_flag
FROM ranked_sales r
WHERE r.rn <= 3
  AND EXISTS (
        SELECT 1
        FROM web_site ws
        WHERE ws.web_open_date_sk = r.d_date_sk
          AND ws.web_manager = 'Lewis Wolf'
    )
ORDER BY r.d_fy_year DESC, r.total_net_paid DESC
LIMIT 100
