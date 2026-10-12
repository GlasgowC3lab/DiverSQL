WITH recent_sales AS (
    SELECT
        'store_sale' AS source,
        d.d_date AS trans_date,
        ss.ss_net_paid AS amount,
        s.s_store_name AS location
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
),
recent_returns AS (
    SELECT
        'catalog_return' AS source,
        d.d_date AS trans_date,
        cr.cr_return_amount AS amount,
        cc.cc_name AS location
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
)
SELECT source, trans_date, amount, location
FROM recent_sales
UNION ALL
SELECT source, trans_date, amount, location
FROM recent_returns
ORDER BY trans_date DESC
LIMIT 100
