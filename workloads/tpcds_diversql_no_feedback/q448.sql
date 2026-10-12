WITH catalog_agg AS (
    SELECT
        'catalog' AS source_type,
        cd.cd_demo_sk AS demographic_id,
        SUM(cr.cr_return_amount) AS total_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 100
      AND cd.cd_purchase_estimate >= 4000
    GROUP BY cd.cd_demo_sk
),
web_agg AS (
    SELECT
        'web' AS source_type,
        cd.cd_demo_sk AS demographic_id,
        SUM(ws.ws_sales_price) AS total_amount
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sales_price > 100
      AND cd.cd_purchase_estimate >= 4000
    GROUP BY cd.cd_demo_sk
)
SELECT
    src.source_type,
    src.demographic_id,
    src.total_amount,
    CASE WHEN src.total_amount > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
    SUM(src.total_amount) OVER (
        PARTITION BY src.source_type
        ORDER BY src.total_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) AS src
ORDER BY src.source_type, running_total DESC
LIMIT 100
