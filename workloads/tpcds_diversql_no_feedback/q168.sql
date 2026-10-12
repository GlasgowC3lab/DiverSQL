WITH returns_summary AS (
    SELECT r.r_reason_desc AS category,
           SUM(cr.cr_return_amount) AS metric
    FROM catalog_returns cr
    FULL OUTER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE (d.d_year = 2001) OR d.d_year IS NULL
    GROUP BY r.r_reason_desc
),
sales_summary AS (
    SELECT wp.wp_type AS category,
           SUM(ws.ws_net_paid) AS metric
    FROM web_sales ws
    FULL OUTER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE (d.d_year = 2001) OR d.d_year IS NULL
    GROUP BY wp.wp_type
)
SELECT category,
       metric
FROM returns_summary
UNION ALL
SELECT category,
       metric
FROM sales_summary
ORDER BY metric DESC
LIMIT 100
