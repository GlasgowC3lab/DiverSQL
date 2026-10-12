WITH all_returns AS (
    SELECT
        cr_returned_date_sk AS return_date_sk,
        cr_return_tax AS tax,
        cr_item_sk AS item_sk,
        'Catalog' AS source
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk AS return_date_sk,
        wr_return_tax AS tax,
        wr_item_sk AS item_sk,
        'Web' AS source
    FROM web_returns
),
returns_with_item AS (
    SELECT
        ar.return_date_sk,
        ar.tax,
        ar.source,
        i.i_category,
        CASE
            WHEN ar.tax < 5 THEN 'Low'
            WHEN ar.tax BETWEEN 5 AND 15 THEN 'Medium'
            ELSE 'High'
        END AS tax_bucket
    FROM all_returns ar
    LEFT JOIN item i ON ar.item_sk = i.i_item_sk
),
aggregated AS (
    SELECT
        return_date_sk,
        tax_bucket,
        i_category,
        SUM(tax) AS total_tax,
        COUNT(*) AS return_cnt
    FROM returns_with_item
    GROUP BY return_date_sk, tax_bucket, i_category
)
SELECT
    return_date_sk,
    tax_bucket,
    i_category,
    total_tax,
    return_cnt,
    SUM(total_tax) OVER (PARTITION BY tax_bucket ORDER BY return_date_sk
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_tax_by_bucket,
    RANK() OVER (PARTITION BY tax_bucket ORDER BY total_tax DESC) AS bucket_rank
FROM aggregated
ORDER BY return_date_sk, tax_bucket
