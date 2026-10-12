WITH store_metrics AS (
    SELECT
        d.d_date AS return_date,
        'store' AS entity_type,
        s.s_store_id AS entity_id,
        t.metric_name,
        t.metric_value
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(
        MAP(
            ARRAY['net_loss', 'fee', 'return_amt'],
            ARRAY[sr.sr_net_loss, sr.sr_fee, sr.sr_return_amt]
        )
    ) AS t(metric_name, metric_value)
    WHERE d.d_year = 2001
),
catalog_metrics AS (
    SELECT
        d.d_date AS return_date,
        'catalog' AS entity_type,
        cp.cp_catalog_page_id AS entity_id,
        t.metric_name,
        t.metric_value
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(
        MAP(
            ARRAY['net_loss', 'fee', 'return_amount'],
            ARRAY[cr.cr_net_loss, cr.cr_fee, cr.cr_return_amount]
        )
    ) AS t(metric_name, metric_value)
    WHERE d.d_year = 2001
)
SELECT *
FROM store_metrics
UNION ALL
SELECT *
FROM catalog_metrics
ORDER BY return_date, entity_type, entity_id, metric_name
LIMIT 100
